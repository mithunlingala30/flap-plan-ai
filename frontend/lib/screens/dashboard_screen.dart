import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/patient_case.dart';
import '../models/prediction.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/outcome_badge.dart';
import '../widgets/outcome_distribution_chart.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';
import 'analytics_screen.dart';
import 'case_detail_screen.dart';
import 'case_entry_screen.dart';
import 'history_screen.dart';

enum _Tab { all, highRisk }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _Tab _tab = _Tab.all;
  YesNo? _diabetesFilter;
  YesNo? _bopFilter;
  SurgicalProcedure? _procFilter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cases = state.savedCases;

    final total = cases.length;
    final goodExc = cases
        .where((c) =>
            c.prediction.predictedClass == HealingOutcome.good ||
            c.prediction.predictedClass == HealingOutcome.excellent)
        .length;
    final poor = cases
        .where((c) => c.prediction.predictedClass == HealingOutcome.poor)
        .length;

    final procCounts = <SurgicalProcedure, int>{};
    for (final c in cases) {
      procCounts[c.patientCase.procedure] =
          (procCounts[c.patientCase.procedure] ?? 0) + 1;
    }
    SurgicalProcedure topProc = SurgicalProcedure.flapSurgery;
    var topN = -1;
    procCounts.forEach((p, n) {
      if (n > topN) {
        topN = n;
        topProc = p;
      }
    });

    final filtered = cases.where((c) {
      if (_tab == _Tab.highRisk && c.prediction.predictedClass != HealingOutcome.poor) {
        return false;
      }
      if (_diabetesFilter != null && c.patientCase.diabetes != _diabetesFilter) return false;
      if (_bopFilter != null && c.patientCase.bleedingOnProbing != _bopFilter) return false;
      if (_procFilter != null && c.patientCase.procedure != _procFilter) return false;
      return true;
    }).toList();

    return AppShell(
      currentTab: ShellTab.dashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Dashboard',
              subtitle: 'Overview of predicted periodontal surgery cases.',
              actions: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.history_edu_outlined, size: 17),
                  label: const Text('All Records'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    );
                  },
                  icon: const Icon(Icons.insights_outlined, size: 17),
                  label: const Text('Analytics'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    state.clearDraft();
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const CaseEntryScreen()));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Case'),
                ),
              ],
            ),

            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 560
                      ? 2
                      : 1;
              final items = [
                StatCard(
                    label: 'Total cases',
                    value: '$total',
                    icon: Icons.layers_outlined,
                    tone: StatTone.brand),
                StatCard(
                  label: 'Good / Excellent',
                  value: total == 0 ? '0%' : '${(goodExc / total * 100).round()}%',
                  sub: 'Predicted favorable healing',
                  icon: Icons.thumb_up_outlined,
                  tone: StatTone.green,
                ),
                StatCard(
                  label: 'Poor outcomes',
                  value: total == 0 ? '0%' : '${(poor / total * 100).round()}%',
                  sub: 'High-risk cases',
                  icon: Icons.warning_amber_outlined,
                  tone: StatTone.red,
                ),
                StatCard(
                  label: 'Most-used procedure',
                  value: cases.isEmpty ? '—' : topProc.label,
                  sub: cases.isEmpty ? null : '${topN.clamp(0, 1 << 30)} cases',
                  icon: Icons.bar_chart_outlined,
                  tone: StatTone.gray,
                ),
              ];
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: cols == 1 ? 2.1 : 1.4,
                children: items,
              );
            }),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 800;
              final distribution = SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Outcome distribution',
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                        Text('Across ${cases.length} cases',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.gray400)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutcomeDistributionChart(cases: cases),
                  ],
                ),
              );
              final filters = SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filters',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                    const SizedBox(height: 16),
                    _FilterDropdown<YesNo?>(
                      label: 'Diabetes',
                      value: _diabetesFilter,
                      items: const {null: 'All', YesNo.yes: 'Yes', YesNo.no: 'No'},
                      onChanged: (v) => setState(() => _diabetesFilter = v),
                    ),
                    const SizedBox(height: 14),
                    _FilterDropdown<YesNo?>(
                      label: 'Bleeding on Probing',
                      value: _bopFilter,
                      items: const {null: 'All', YesNo.yes: 'Yes', YesNo.no: 'No'},
                      onChanged: (v) => setState(() => _bopFilter = v),
                    ),
                    const SizedBox(height: 14),
                    _FilterDropdown<SurgicalProcedure?>(
                      label: 'Procedure',
                      value: _procFilter,
                      items: {
                        null: 'All',
                        for (final p in kProcedures) p: p.label,
                      },
                      onChanged: (v) => setState(() => _procFilter = v),
                    ),
                  ],
                ),
              );
              if (!wide) {
                return Column(children: [distribution, const SizedBox(height: 16), filters]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: distribution),
                  const SizedBox(width: 16),
                  Expanded(child: filters),
                ],
              );
            }),
            const SizedBox(height: 24),
            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _TabButton(
                              label: 'All cases',
                              active: _tab == _Tab.all,
                              onTap: () => setState(() => _tab = _Tab.all),
                            ),
                            const SizedBox(width: 6),
                            _TabButton(
                              label: 'High-risk',
                              icon: Icons.warning_amber_outlined,
                              active: _tab == _Tab.highRisk,
                              onTap: () => setState(() => _tab = _Tab.highRisk),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${filtered.length} case${filtered.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.gray400),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (state.casesLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text('No cases match the current filters.',
                            style: TextStyle(color: AppColors.gray400)),
                      ),
                    )
                  else
                    _CasesTable(cases: filtered),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.gray500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: items.entries
              .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => onChanged(v as T),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({required this.label, this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.brand600 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: active ? AppColors.brand700 : AppColors.gray500),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.brand700 : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CasesTable extends StatelessWidget {
  final List<SavedCase> cases;

  const _CasesTable({required this.cases});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 52,
        columns: const [
          DataColumn(label: Text('Case ID')),
          DataColumn(label: Text('Age')),
          DataColumn(label: Text('Sex')),
          DataColumn(label: Text('Diabetes')),
          DataColumn(label: Text('Procedure')),
          DataColumn(label: Text('Predicted')),
          DataColumn(label: Text('Date')),
        ],
        rows: cases
            .map((c) => DataRow(
                  onSelectChanged: (_) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CaseDetailScreen(caseId: c.id),
                    ));
                  },
                  cells: [
                    DataCell(Text(c.id,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.brand700))),
                    DataCell(Text('${c.patientCase.age}')),
                    DataCell(Text(c.patientCase.sex.label)),
                    DataCell(Text(c.patientCase.diabetes.label)),
                    DataCell(Text(c.patientCase.procedure.label)),
                    DataCell(OutcomeBadge(outcome: c.prediction.predictedClass, size: BadgeSize.sm)),
                    DataCell(Text(dateFmt.format(c.date),
                        style: const TextStyle(color: AppColors.gray500))),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
