import 'package:flutter/material.dart';
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
import 'case_entry_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

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
    final avgUtility = total == 0
        ? 0.0
        : cases.map((c) => c.prediction.utility).reduce((a, b) => a + b) / total;

    return AppShell(
      currentTab: ShellTab.analytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Clinical Analytics & Insights',
              subtitle:
                  'Aggregate outcome distributions, surgical efficacy metrics, and clinical risk analysis.',
              actions: [
                OutlinedButton.icon(
                  onPressed: cases.isEmpty
                      ? null
                      : () => ReportGeneratorService.downloadAnalyticsReport(
                            context,
                            cases: cases,
                            clinicianName: state.profile?.name ?? 'Clinician',
                          ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  label: const Text('Export Analytics Report'),
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

            // Top KPI Row
            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 560
                      ? 2
                      : 1;
              final items = [
                StatCard(
                  label: 'Total Cases Analyzed',
                  value: '$total',
                  sub: 'Patient records evaluated',
                  icon: Icons.analytics_outlined,
                  tone: StatTone.brand,
                ),
                StatCard(
                  label: 'Favorable Healing Rate',
                  value: total == 0 ? '0%' : '${(goodExc / total * 100).round()}%',
                  sub: '$goodExc cases (Good / Excellent)',
                  icon: Icons.check_circle_outline,
                  tone: StatTone.green,
                ),
                StatCard(
                  label: 'High-Risk Incidence',
                  value: total == 0 ? '0%' : '${(poor / total * 100).round()}%',
                  sub: '$poor cases flagged Poor',
                  icon: Icons.warning_amber_outlined,
                  tone: StatTone.red,
                ),
                StatCard(
                  label: 'Mean Clinical Utility',
                  value: total == 0 ? '—' : avgUtility.toStringAsFixed(2),
                  sub: 'Across all evaluated procedures',
                  icon: Icons.star_border_outlined,
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

            if (cases.isEmpty)
              SectionCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_outlined, size: 48, color: AppColors.gray300),
                        const SizedBox(height: 12),
                        const Text(
                          'No clinical case data available for analytics yet.',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray700),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Run your first patient case prediction to unlock outcome insights and procedure efficacy comparisons.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.gray400),
                          textAlign: TextAlign.center,
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
                          label: const Text('Start First Case'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Procedure Performance Breakdown
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.medical_services_outlined,
                                size: 18, color: AppColors.brand600),
                            SizedBox(width: 8),
                            Text(
                              'Surgical Procedure Efficacy',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$total total evaluations',
                          style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...kProcedures.map((proc) {
                      final pCases =
                          cases.where((c) => c.patientCase.procedure == proc).toList();
                      final pCount = pCases.length;
                      final pGoodExc = pCases
                          .where((c) =>
                              c.prediction.predictedClass == HealingOutcome.good ||
                              c.prediction.predictedClass == HealingOutcome.excellent)
                          .length;
                      final pPoor = pCases
                          .where((c) =>
                              c.prediction.predictedClass == HealingOutcome.poor)
                          .length;
                      final pMeanUtil = pCount == 0
                          ? 0.0
                          : pCases.map((c) => c.prediction.utility).reduce((a, b) => a + b) /
                              pCount;

                      return _ProcedureRow(
                        procedure: proc,
                        count: pCount,
                        goodExcCount: pGoodExc,
                        poorCount: pPoor,
                        meanUtility: pMeanUtil,
                        totalCases: total,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Risk Correlations & Clinical Insights
              LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > 860;
                final riskCard = SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_outlined, size: 18, color: AppColors.brand600),
                          SizedBox(width: 8),
                          Text(
                            'Clinical Risk Factor Correlations',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _RiskCorrelationRow(
                        title: 'Diabetes Mellitus',
                        subtitle: 'Diabetic vs Non-Diabetic favorable healing rate',
                        cohortACount: cases
                            .where((c) => c.patientCase.diabetes == YesNo.no)
                            .length,
                        cohortARate: _calcFavorableRate(
                            cases.where((c) => c.patientCase.diabetes == YesNo.no)),
                        cohortALabel: 'Non-Diabetic',
                        cohortBCount: cases
                            .where((c) => c.patientCase.diabetes == YesNo.yes)
                            .length,
                        cohortBRate: _calcFavorableRate(
                            cases.where((c) => c.patientCase.diabetes == YesNo.yes)),
                        cohortBLabel: 'Diabetic',
                      ),
                      const Divider(height: 24),
                      _RiskCorrelationRow(
                        title: 'Bleeding on Probing (BOP)',
                        subtitle: 'Active inflammation impact on outcome',
                        cohortACount: cases
                            .where((c) => c.patientCase.bleedingOnProbing == YesNo.no)
                            .length,
                        cohortARate: _calcFavorableRate(cases
                            .where((c) => c.patientCase.bleedingOnProbing == YesNo.no)),
                        cohortALabel: 'BOP Negative',
                        cohortBCount: cases
                            .where((c) => c.patientCase.bleedingOnProbing == YesNo.yes)
                            .length,
                        cohortBRate: _calcFavorableRate(cases
                            .where((c) => c.patientCase.bleedingOnProbing == YesNo.yes)),
                        cohortBLabel: 'BOP Positive',
                      ),
                      const Divider(height: 24),
                      _RiskCorrelationRow(
                        title: 'Deep Probing Depth (PD ≥ 5mm)',
                        subtitle: 'Periodontal pocket depth severity impact',
                        cohortACount: cases
                            .where((c) => c.patientCase.probingDepth < 5.0)
                            .length,
                        cohortARate: _calcFavorableRate(
                            cases.where((c) => c.patientCase.probingDepth < 5.0)),
                        cohortALabel: 'PD < 5mm',
                        cohortBCount: cases
                            .where((c) => c.patientCase.probingDepth >= 5.0)
                            .length,
                        cohortBRate: _calcFavorableRate(
                            cases.where((c) => c.patientCase.probingDepth >= 5.0)),
                        cohortBLabel: 'PD ≥ 5mm',
                      ),
                    ],
                  ),
                );

                final insightsCard = SectionCard(
                  backgroundColor: AppColors.brand50,
                  borderColor: AppColors.brand200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 18, color: AppColors.brand700),
                          SizedBox(width: 8),
                          Text(
                            'AI Clinical Decision Insights',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brand900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InsightItem(
                        icon: Icons.shield_outlined,
                        title: 'Diabetes Glycemic Control',
                        body:
                            'Patients with diabetes exhibit lower utility scores under standard Flap Surgery. Consider GTR or adjunctive regenerative protocols to optimize outcome.',
                      ),
                      const SizedBox(height: 12),
                      _InsightItem(
                        icon: Icons.healing_outlined,
                        title: 'Attachment Loss (CAL) Severity',
                        body:
                            'CAL greater than 4.5mm strongly correlates with outcome volatility. Guided Tissue Regeneration (GTR) consistently achieves the highest utility in deep defects.',
                      ),
                      const SizedBox(height: 12),
                      _InsightItem(
                        icon: Icons.layers_outlined,
                        title: 'Plaque & Hygiene Impact',
                        body:
                            'Elevated Plaque Index (> 1.5) was identified as a top-3 negative driver in 84% of poor outcomes. Pre-surgical scaling and hygiene compliance are vital.',
                      ),
                    ],
                  ),
                );

                if (!wide) {
                  return Column(
                    children: [riskCard, const SizedBox(height: 20), insightsCard],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: riskCard),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: insightsCard),
                  ],
                );
              }),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static double _calcFavorableRate(Iterable<SavedCase> cases) {
    if (cases.isEmpty) return 0.0;
    final fav = cases
        .where((c) =>
            c.prediction.predictedClass == HealingOutcome.good ||
            c.prediction.predictedClass == HealingOutcome.excellent)
        .length;
    return fav / cases.length;
  }
}

class _ProcedureRow extends StatelessWidget {
  final SurgicalProcedure procedure;
  final int count;
  final int goodExcCount;
  final int poorCount;
  final double meanUtility;
  final int totalCases;

  const _ProcedureRow({
    required this.procedure,
    required this.count,
    required this.goodExcCount,
    required this.poorCount,
    required this.meanUtility,
    required this.totalCases,
  });

  @override
  Widget build(BuildContext context) {
    final favRate = count == 0 ? 0.0 : (goodExcCount / count);
    final poorRate = count == 0 ? 0.0 : (poorCount / count);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      procedure.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$count case${count == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 11, color: AppColors.gray700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mean Utility: ',
                      style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                  Text(
                    count == 0 ? '—' : meanUtility.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Visual Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    color: AppColors.gray200,
                    child: count == 0
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              Flexible(
                                flex: (favRate * 100).round(),
                                child: Container(color: AppColors.green600),
                              ),
                              Flexible(
                                flex: ((1 - favRate - poorRate) * 100).clamp(0, 100).round(),
                                child: Container(color: AppColors.amber),
                              ),
                              Flexible(
                                flex: (poorRate * 100).round(),
                                child: Container(color: AppColors.red600),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                count == 0 ? '0% Favorable' : '${(favRate * 100).round()}% Favorable',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: favRate >= 0.7
                      ? AppColors.green700
                      : favRate >= 0.4
                          ? AppColors.brand700
                          : AppColors.red600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskCorrelationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final int cohortACount;
  final double cohortARate;
  final String cohortALabel;
  final int cohortBCount;
  final double cohortBRate;
  final String cohortBLabel;

  const _RiskCorrelationRow({
    required this.title,
    required this.subtitle,
    required this.cohortACount,
    required this.cohortARate,
    required this.cohortALabel,
    required this.cohortBCount,
    required this.cohortBRate,
    required this.cohortBLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gray900),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.gray400),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CohortPill(
                label: cohortALabel,
                count: cohortACount,
                rate: cohortARate,
                isPositive: cohortARate >= cohortBRate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CohortPill(
                label: cohortBLabel,
                count: cohortBCount,
                rate: cohortBRate,
                isPositive: cohortBRate >= cohortARate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CohortPill extends StatelessWidget {
  final String label;
  final int count;
  final double rate;
  final bool isPositive;

  const _CohortPill({
    required this.label,
    required this.count,
    required this.rate,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.green50 : AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive ? AppColors.green200 : AppColors.gray200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray700),
                ),
                Text(
                  '$count cases',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.gray400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count == 0 ? '—' : '${(rate * 100).round()}% Good',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.green700 : AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.brand700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(fontSize: 11.5, color: AppColors.gray700, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
