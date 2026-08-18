/// Shared premium widgets used across the case detail and result screens.
library;

import 'package:flutter/material.dart';

import '../models/patient_case.dart';
import '../models/prediction.dart';
import '../services/local_prediction_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/outcome_badge.dart';
import '../widgets/outcome_bars.dart';
import '../widgets/outcome_style.dart';
import '../widgets/section_card.dart';
import '../widgets/drivers_panel.dart';
import '../widgets/case_summary.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Outcome Hero Banner
// ──────────────────────────────────────────────────────────────────────────────
class OutcomeHeroBanner extends StatelessWidget {
  final Prediction prediction;
  final OutcomeStyle style;
  final String caseId;
  final DateTime date;

  const OutcomeHeroBanner({
    super.key,
    required this.prediction,
    required this.style,
    required this.caseId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            style.bg,
            style.bg.withValues(alpha: 0.4),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: style.bar.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 560;

          final iconWidget = Container(
            width: isWide ? 64 : 48,
            height: isWide ? 64 : 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.bg,
              shape: BoxShape.circle,
              border: Border.all(color: style.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: style.bar.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(style.icon, size: isWide ? 30 : 22, color: style.text),
          );

          final detailsWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PREDICTED HEALING OUTCOME',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.gray400,
                ),
              ),
              const SizedBox(height: 6),
              OutcomeBadge(outcome: prediction.predictedClass, size: isWide ? BadgeSize.hero : BadgeSize.lg),
              const SizedBox(height: 6),
              Text(
                _outcomeDescription(prediction.predictedClass),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.gray500,
                  height: 1.4,
                ),
              ),
            ],
          );

          final utilityWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'UTILITY SCORE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prediction.utility.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: isWide ? 30 : 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                UtilityMiniBar(utility: prediction.utility),
              ],
            ),
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconWidget,
                    const SizedBox(width: 14),
                    Expanded(child: detailsWidget),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Utility Score',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray800,
                            ),
                          ),
                          Text(
                            'Quantified clinical value',
                            style: TextStyle(fontSize: 10, color: AppColors.gray400),
                          ),
                        ],
                      ),
                      utilityWidget,
                    ],
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 20),
              Expanded(child: detailsWidget),
              const SizedBox(width: 20),
              utilityWidget,
            ],
          );
        },
      ),
    );
  }

  String _outcomeDescription(HealingOutcome o) => switch (o) {
        HealingOutcome.excellent =>
          'Outstanding post-operative healing is projected with high confidence.',
        HealingOutcome.good => 'Good recovery expected. Continue standard post-op protocols.',
        HealingOutcome.fair =>
          'Moderate healing likelihood. Consider optimizing risk factors.',
        HealingOutcome.poor =>
          'Elevated risk of poor healing. Review case carefully before proceeding.',
      };
}

class UtilityMiniBar extends StatelessWidget {
  final double utility;
  const UtilityMiniBar({super.key, required this.utility});

  @override
  Widget build(BuildContext context) {
    final pct = ((utility + 2) / 4).clamp(0.0, 1.0);
    final barColor = pct < 0.33
        ? const Color(0xFFEF4444)
        : pct < 0.6
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return SizedBox(
      width: 90,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 4,
          color: AppColors.gray100,
          child: LayoutBuilder(builder: (_, c) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              width: c.maxWidth * pct,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stats Ribbon
// ──────────────────────────────────────────────────────────────────────────────
class StatsRibbon extends StatelessWidget {
  final Prediction prediction;
  final List<ProcedurePrediction> procedures;

  const StatsRibbon({super.key, required this.prediction, required this.procedures});

  @override
  Widget build(BuildContext context) {
    final p = prediction.probabilities;
    final favorable = ((p.good + p.excellent) * 100).toStringAsFixed(0);
    final poor = (p.poor * 100).toStringAsFixed(0);

    final chips = [
      StatChip(
        icon: Icons.thumb_up_outlined,
        label: 'Favorable Prob.',
        value: '$favorable%',
        color: const Color(0xFF10B981),
      ),
      StatChip(
        icon: Icons.warning_amber_rounded,
        label: 'Poor Outcome Risk',
        value: '$poor%',
        color: const Color(0xFFEF4444),
      ),
      StatChip(
        icon: Icons.science_outlined,
        label: 'Procedures Compared',
        value: '${procedures.length}',
        color: AppColors.brand600,
      ),
      StatChip(
        icon: Icons.emoji_events_outlined,
        label: 'Best Procedure',
        value: procedures.first.procedure.label,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 500;
      if (wide) {
        return Row(
          children: chips
              .map((c) => Expanded(child: c))
              .expand((w) => [w, const SizedBox(width: 10)])
              .toList()
            ..removeLast(),
        );
      }
      return Wrap(spacing: 10, runSpacing: 10, children: chips);
    });
  }
}

class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Recommendation Card
// ──────────────────────────────────────────────────────────────────────────────
class RecommendationCard extends StatelessWidget {
  final ProcedurePrediction best;
  final String enteredLabel;
  final String reason;

  const RecommendationCard({
    super.key,
    required this.best,
    required this.enteredLabel,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final isSame = best.procedure.label == enteredLabel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDFB), Color(0xFFE6F7F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand600.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brand50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brand200),
            ),
            child:
                const Icon(Icons.emoji_events_rounded, size: 22, color: AppColors.brand600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI RECOMMENDED PROCEDURE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.brand700,
                      ),
                    ),
                    if (isSame) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF6EE7B7)),
                        ),
                        child: const Text(
                          '✓ Matches entered',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  best.procedure.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Utility ${best.utility.toStringAsFixed(2)} · vs. $enteredLabel (entered)',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.gray500),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.brand100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 15, color: AppColors.brand600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.gray700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Card Header
// ──────────────────────────────────────────────────────────────────────────────
class CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const CardHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.gray800,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Full Result/Detail Body – shared between ResultScreen & CaseDetailScreen
// ──────────────────────────────────────────────────────────────────────────────
class PredictionDetailBody extends StatelessWidget {
  final Prediction prediction;
  final PatientCase patientCase;

  const PredictionDetailBody({
    super.key,
    required this.prediction,
    required this.patientCase,
  });

  @override
  Widget build(BuildContext context) {
    final style = kOutcomeStyles[prediction.predictedClass]!;
    final procedures = LocalPredictionEngine.predictAllProcedures(patientCase);
    final best = procedures.first;
    final reason = LocalPredictionEngine.recommendationReason(best, patientCase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutcomeHeroBanner(
          prediction: prediction,
          style: style,
          caseId: '',
          date: DateTime.now(),
        ),
        const SizedBox(height: 16),
        StatsRibbon(prediction: prediction, procedures: procedures),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 760;

          final probCard = SectionCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHeader(
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppColors.brand600,
                  title: 'Probability Breakdown',
                ),
                const SizedBox(height: 16),
                OutcomeBars(
                  probabilities: prediction.probabilities,
                  highlightOutcome: prediction.predictedClass,
                ),
              ],
            ),
          );

          final driversCard = SectionCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHeader(
                  icon: Icons.insights_rounded,
                  iconColor: AppColors.brand600,
                  title: 'Top Predictive Drivers',
                ),
                const SizedBox(height: 14),
                DriversPanel(drivers: prediction.drivers),
              ],
            ),
          );

          return Column(
            children: [
              wide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 5, child: probCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: driversCard),
                    ])
                  : Column(children: [probCard, const SizedBox(height: 16), driversCard]),
              const SizedBox(height: 16),
              RecommendationCard(
                best: best,
                enteredLabel: patientCase.procedure.label,
                reason: reason,
              ),
              const SizedBox(height: 16),
              SectionCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardHeader(
                      icon: Icons.assignment_outlined,
                      iconColor: AppColors.gray500,
                      title: 'Case Inputs',
                    ),
                    const SizedBox(height: 14),
                    CaseSummary(c: patientCase),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
