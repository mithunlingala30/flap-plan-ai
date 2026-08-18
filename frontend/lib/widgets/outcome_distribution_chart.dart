import 'package:flutter/material.dart';

import '../models/patient_case.dart';
import '../models/prediction.dart';
import '../theme/app_theme.dart';
import 'outcome_style.dart';

class OutcomeDistributionChart extends StatelessWidget {
  final List<SavedCase> cases;

  const OutcomeDistributionChart({super.key, required this.cases});

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final o in kOutcomes)
        o: cases.where((c) => c.prediction.predictedClass == o).length,
    };
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxCount == 0 ? 1 : maxCount;

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final o in kOutcomes)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${counts[o]}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: counts[o]! / safeMax),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => Container(
                        height: 150 * value,
                        decoration: BoxDecoration(
                          color: kOutcomeStyles[o]!.bar,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o.label,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
