import 'package:flutter/material.dart';

import '../models/patient_case.dart';
import 'outcome_style.dart';

enum BadgeSize { sm, md, lg, hero }

class OutcomeBadge extends StatelessWidget {
  final HealingOutcome outcome;
  final BadgeSize size;

  const OutcomeBadge({super.key, required this.outcome, this.size = BadgeSize.md});

  @override
  Widget build(BuildContext context) {
    final style = kOutcomeStyles[outcome]!;

    final double fontSize = switch (size) {
      BadgeSize.hero => 16,
      BadgeSize.lg => 14,
      BadgeSize.sm => 11.5,
      BadgeSize.md => 13,
    };

    final double iconSize = switch (size) {
      BadgeSize.hero => 18,
      BadgeSize.lg => 16,
      BadgeSize.sm => 12,
      BadgeSize.md => 14,
    };

    final EdgeInsets padding = switch (size) {
      BadgeSize.hero => const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      BadgeSize.lg => const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      BadgeSize.sm => const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      BadgeSize.md => const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: style.bg,
        border: Border.all(color: style.border, width: 1.2),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: style.bar.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: iconSize, color: style.text),
          const SizedBox(width: 6),
          Text(
            outcome.label,
            style: TextStyle(
              color: style.text,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
