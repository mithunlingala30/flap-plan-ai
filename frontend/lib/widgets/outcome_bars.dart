import 'package:flutter/material.dart';

import '../models/patient_case.dart';
import '../models/prediction.dart';
import '../theme/app_theme.dart';
import 'outcome_style.dart';

class OutcomeBars extends StatelessWidget {
  final OutcomeProbabilities probabilities;
  final bool compact;
  final HealingOutcome? highlightOutcome;

  const OutcomeBars({
    super.key,
    required this.probabilities,
    this.compact = false,
    this.highlightOutcome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in kOutcomes) ...[
          _OutcomeBarRow(
            outcome: o,
            value: probabilities[o],
            compact: compact,
            isHighlighted: highlightOutcome == o,
          ),
          if (o != kOutcomes.last) SizedBox(height: compact ? 8 : 10),
        ],
      ],
    );
  }
}

class _OutcomeBarRow extends StatefulWidget {
  final HealingOutcome outcome;
  final double value;
  final bool compact;
  final bool isHighlighted;

  const _OutcomeBarRow({
    required this.outcome,
    required this.value,
    required this.compact,
    required this.isHighlighted,
  });

  @override
  State<_OutcomeBarRow> createState() => _OutcomeBarRowState();
}

class _OutcomeBarRowState extends State<_OutcomeBarRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final style = kOutcomeStyles[widget.outcome]!;
    final pct = widget.value.clamp(0.0, 1.0);
    final isTop = widget.isHighlighted;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 6 : 12,
          vertical: widget.compact ? 5 : 8,
        ),
        decoration: BoxDecoration(
          color: isTop
              ? style.bg.withValues(alpha: 0.7)
              : _isHovered
                  ? AppColors.gray50
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isTop
                ? style.border
                : _isHovered
                    ? AppColors.gray200
                    : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Category Icon & Label
            SizedBox(
              width: widget.compact ? 70 : 100,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: style.bar,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: style.bar.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.outcome.label,
                      style: TextStyle(
                        fontSize: widget.compact ? 12 : 13,
                        fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                        color: isTop ? style.text : AppColors.gray700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Progress Bar Track & Fill
            Expanded(
              child: Container(
                height: widget.compact ? 8 : 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final targetWidth = constraints.maxWidth * pct;
                    return Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          width: targetWidth.clamp(pct > 0.005 ? 6.0 : 0.0, constraints.maxWidth),
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: style.gradient,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: style.bar.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Percentage Badge
            Container(
              constraints: BoxConstraints(minWidth: widget.compact ? 42 : 56),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: isTop ? style.bg : AppColors.gray100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isTop ? style.border : AppColors.gray200,
                  width: 0.8,
                ),
              ),
              child: Text(
                pctText(widget.value),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: widget.compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: isTop ? style.text : AppColors.gray800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
