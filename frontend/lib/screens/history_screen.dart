import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/patient_case.dart';
import '../models/prediction.dart';
import '../services/report_generator_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/outcome_badge.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';
import 'case_detail_screen.dart';
import 'case_entry_screen.dart';
import 'compare_screen.dart';

enum _SortBy { newest, oldest, utilityHigh, utilityLow, ageHigh, ageLow }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  HealingOutcome? _outcomeFilter;
  SurgicalProcedure? _procFilter;
  YesNo? _diabetesFilter;
  YesNo? _bopFilter;
  _SortBy _sortBy = _SortBy.newest;
  bool _tableView = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allCases = state.savedCases;

    // Filter
    final filtered = allCases.where((c) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matchesId = c.id.toLowerCase().contains(q);
        final matchesProc = c.patientCase.procedure.label.toLowerCase().contains(q);
        final matchesOutcome = c.prediction.predictedClass.label.toLowerCase().contains(q);
        if (!matchesId && !matchesProc && !matchesOutcome) return false;
      }
      if (_outcomeFilter != null && c.prediction.predictedClass != _outcomeFilter) {
        return false;
      }
      if (_procFilter != null && c.patientCase.procedure != _procFilter) {
        return false;
      }
      if (_diabetesFilter != null && c.patientCase.diabetes != _diabetesFilter) {
        return false;
      }
      if (_bopFilter != null && c.patientCase.bleedingOnProbing != _bopFilter) {
        return false;
      }
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case _SortBy.newest:
          return b.date.compareTo(a.date);
        case _SortBy.oldest:
          return a.date.compareTo(b.date);
        case _SortBy.utilityHigh:
          return b.prediction.utility.compareTo(a.prediction.utility);
        case _SortBy.utilityLow:
          return a.prediction.utility.compareTo(b.prediction.utility);
        case _SortBy.ageHigh:
          return b.patientCase.age.compareTo(a.patientCase.age);
        case _SortBy.ageLow:
          return a.patientCase.age.compareTo(b.patientCase.age);
      }
    });

    final total = allCases.length;
    final goodExc = allCases
        .where((c) =>
            c.prediction.predictedClass == HealingOutcome.good ||
            c.prediction.predictedClass == HealingOutcome.excellent)
        .length;
    final poor = allCases
        .where((c) => c.prediction.predictedClass == HealingOutcome.poor)
        .length;

    return AppShell(
      currentTab: ShellTab.history,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Case History & Records',
              subtitle: 'Search, filter, compare, and download clinical case reports.',
              actions: [
                OutlinedButton.icon(
                  onPressed: filtered.isEmpty
                      ? null
                      : () => _exportCsv(context, filtered),
                  icon: const Icon(Icons.table_view_outlined, size: 17),
                  label: const Text('Export CSV'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    state.clearDraft();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CaseEntryScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Case'),
                ),
              ],
            ),

            // Top Stat Cards
            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 560
                      ? 3
                      : 1;
              final items = [
                StatCard(
                  label: 'Total Saved Records',
                  value: '$total',
                  sub: 'Historical evaluations in database',
                  icon: Icons.inventory_2_outlined,
                  tone: StatTone.brand,
                ),
                StatCard(
                  label: 'Favorable Prognosis',
                  value: total == 0 ? '0%' : '${(goodExc / total * 100).round()}%',
                  sub: '$goodExc cases (Good / Excellent)',
                  icon: Icons.thumb_up_outlined,
                  tone: StatTone.green,
                ),
                StatCard(
                  label: 'High-Risk Cases',
                  value: total == 0 ? '0%' : '${(poor / total * 100).round()}%',
                  sub: '$poor cases flagged with poor healing',
                  icon: Icons.warning_amber_outlined,
                  tone: StatTone.red,
                ),
              ];
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: cols == 1 ? 2.1 : 1.8,
                children: items,
              );
            }),
            const SizedBox(height: 20),

            // Filter & Search Controls Card
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search by Case ID (e.g. PT-0341), procedure, outcome...',
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.gray400),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // View toggle
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.grid_view_outlined,
                                size: 20,
                                color: !_tableView ? AppColors.brand700 : AppColors.gray500,
                              ),
                              tooltip: 'Card View',
                              onPressed: () => setState(() => _tableView = false),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.format_list_bulleted,
                                size: 20,
                                color: _tableView ? AppColors.brand700 : AppColors.gray500,
                              ),
                              tooltip: 'Table View',
                              onPressed: () => setState(() => _tableView = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Filter dropdowns
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _CompactDropdown<HealingOutcome?>(
                        label: 'Outcome',
                        value: _outcomeFilter,
                        items: {
                          null: 'All Outcomes',
                          HealingOutcome.excellent: 'Excellent',
                          HealingOutcome.good: 'Good',
                          HealingOutcome.fair: 'Fair',
                          HealingOutcome.poor: 'Poor',
                        },
                        onChanged: (v) => setState(() => _outcomeFilter = v),
                      ),
                      _CompactDropdown<SurgicalProcedure?>(
                        label: 'Procedure',
                        value: _procFilter,
                        items: {
                          null: 'All Procedures',
                          for (final p in kProcedures) p: p.label,
                        },
                        onChanged: (v) => setState(() => _procFilter = v),
                      ),
                      _CompactDropdown<YesNo?>(
                        label: 'Diabetes',
                        value: _diabetesFilter,
                        items: const {
                          null: 'Diabetes: All',
                          YesNo.yes: 'Diabetes: Yes',
                          YesNo.no: 'Diabetes: No',
                        },
                        onChanged: (v) => setState(() => _diabetesFilter = v),
                      ),
                      _CompactDropdown<YesNo?>(
                        label: 'BOP',
                        value: _bopFilter,
                        items: const {
                          null: 'BOP: All',
                          YesNo.yes: 'BOP: Yes',
                          YesNo.no: 'BOP: No',
                        },
                        onChanged: (v) => setState(() => _bopFilter = v),
                      ),
                      _CompactDropdown<_SortBy>(
                        label: 'Sort',
                        value: _sortBy,
                        items: const {
                          _SortBy.newest: 'Sort: Newest first',
                          _SortBy.oldest: 'Sort: Oldest first',
                          _SortBy.utilityHigh: 'Sort: Utility (High to Low)',
                          _SortBy.utilityLow: 'Sort: Utility (Low to High)',
                          _SortBy.ageHigh: 'Sort: Age (Oldest to Youngest)',
                          _SortBy.ageLow: 'Sort: Age (Youngest to Oldest)',
                        },
                        onChanged: (v) => setState(() => _sortBy = v ?? _SortBy.newest),
                      ),
                      if (_searchQuery.isNotEmpty ||
                          _outcomeFilter != null ||
                          _procFilter != null ||
                          _diabetesFilter != null ||
                          _bopFilter != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _outcomeFilter = null;
                              _procFilter = null;
                              _diabetesFilter = null;
                              _bopFilter = null;
                            });
                          },
                          icon: const Icon(Icons.filter_alt_off, size: 16),
                          label: const Text('Reset filters', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cases Content
            if (state.casesLoading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              SectionCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off, size: 48, color: AppColors.gray300),
                        const SizedBox(height: 12),
                        const Text(
                          'No historical cases found matching your criteria.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try adjusting your search queries or filters, or create a new case.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.gray400),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            state.clearDraft();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CaseEntryScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create New Case'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_tableView)
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'Showing ${filtered.length} matching case record${filtered.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Divider(height: 1),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 42,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 56,
                        columns: const [
                          DataColumn(label: Text('Case ID')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Patient')),
                          DataColumn(label: Text('Procedure')),
                          DataColumn(label: Text('Outcome')),
                          DataColumn(label: Text('Utility')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filtered.map((c) {
                          final dateFmt = DateFormat('MMM d, yyyy');
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  c.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brand700,
                                  ),
                                ),
                                onTap: () => _openCaseDetail(context, c.id),
                              ),
                              DataCell(Text(dateFmt.format(c.date), style: const TextStyle(fontSize: 12.5, color: AppColors.gray600))),
                              DataCell(Text('${c.patientCase.age}y, ${c.patientCase.sex.label} (PD ${c.patientCase.probingDepth}mm)')),
                              DataCell(Text(c.patientCase.procedure.label)),
                              DataCell(OutcomeBadge(outcome: c.prediction.predictedClass, size: BadgeSize.sm)),
                              DataCell(
                                Text(
                                  c.prediction.utility.toStringAsFixed(2),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.brand600),
                                      tooltip: 'Download PDF Report',
                                      onPressed: () => _downloadReport(context, c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.gray600),
                                      tooltip: 'View Details',
                                      onPressed: () => _openCaseDetail(context, c.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red600),
                                      tooltip: 'Delete Case',
                                      onPressed: () => _confirmDelete(context, c),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Cards Grid / List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  return _CaseHistoryCard(
                    savedCase: c,
                    onView: () => _openCaseDetail(context, c.id),
                    onDownload: () => _downloadReport(context, c),
                    onCompare: () {
                      context.read<AppState>().setDraft(c.patientCase);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CompareScreen()),
                      );
                    },
                    onDelete: () => _confirmDelete(context, c),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _openCaseDetail(BuildContext context, String caseId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: caseId)),
    );
  }

  Future<void> _downloadReport(BuildContext context, SavedCase c) async {
    final state = context.read<AppState>();
    await ReportGeneratorService.downloadOrPrintCaseReport(
      context,
      patientCase: c.patientCase,
      prediction: c.prediction,
      caseId: c.id,
      date: c.date,
      clinicianName: state.profile?.name ?? 'Clinician',
      clinicName: 'Periodontal Surgery Clinic',
    );
  }


  void _exportCsv(BuildContext context, List<SavedCase> cases) {
    final csvContent = ReportGeneratorService.generateCsvData(cases);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.table_chart_outlined, color: AppColors.brand600),
            SizedBox(width: 8),
            Text('Export Cases CSV'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Successfully generated CSV export for ${cases.length} patient records.',
                style: const TextStyle(fontSize: 13, color: AppColors.gray700),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 120,
                child: SingleChildScrollView(
                  child: SelectableText(
                    csvContent,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select and copy the CSV text above to import into Excel, R, Python, or Google Sheets.',
                style: TextStyle(fontSize: 11, color: AppColors.gray500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SavedCase c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Case Record?'),
        content: Text(
          'Are you sure you want to permanently delete case ${c.id}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await context.read<AppState>().deleteCase(c.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Case ${c.id} deleted successfully.')),
        );
      }
    }
  }
}

class _CaseHistoryCard extends StatelessWidget {
  final SavedCase savedCase;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onCompare;
  final VoidCallback onDelete;

  const _CaseHistoryCard({
    required this.savedCase,
    required this.onView,
    required this.onDownload,
    required this.onCompare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = savedCase.patientCase;
    final pred = savedCase.prediction;
    final dateFmt = DateFormat('MMM d, yyyy • HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.brand50,
                        border: Border.all(color: AppColors.brand200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        savedCase.id,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brand700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dateFmt.format(savedCase.date),
                      style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                    ),
                  ],
                ),
                OutcomeBadge(outcome: pred.predictedClass, size: BadgeSize.sm),
              ],
            ),
            const SizedBox(height: 14),

            // Parameters summary chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _paramChip(Icons.person_outline, '${p.age}y, ${p.sex.label}'),
                _paramChip(Icons.medical_services_outlined, p.procedure.label),
                _paramChip(Icons.straighten, 'PD: ${p.probingDepth}mm'),
                _paramChip(Icons.height, 'CAL: ${p.clinicalAttachmentLoss}mm'),
                if (p.diabetes == YesNo.yes)
                  _alertChip('Diabetes: Yes', isWarning: true),
                if (p.bleedingOnProbing == YesNo.yes)
                  _alertChip('BOP: Yes', isWarning: true),
              ],
            ),
            const Divider(height: 24),

            // Footer with Utility & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Utility Score: ',
                        style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                    Text(
                      pred.utility.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                      label: const Text('Download PDF', style: TextStyle(fontSize: 12)),
                    ),
                    OutlinedButton.icon(
                      onPressed: onCompare,
                      icon: const Icon(Icons.compare_arrows, size: 15),
                      label: const Text('Compare', style: TextStyle(fontSize: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.arrow_forward, size: 15),
                      label: const Text('View Case', style: TextStyle(fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray400),
                      tooltip: 'Delete',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paramChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.gray600),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.gray700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _alertChip(String text, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.amberBg : AppColors.gray100,
        border: Border.all(color: isWarning ? AppColors.amberBorder : AppColors.gray200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isWarning ? const Color(0xFFB45309) : AppColors.gray700,
        ),
      ),
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  const _CompactDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: AppColors.gray800, fontWeight: FontWeight.w500),
          items: items.entries
              .map((e) => DropdownMenuItem<T>(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
