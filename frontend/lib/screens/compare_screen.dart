import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/patient_case.dart';
import '../models/prediction.dart';
import '../services/local_prediction_engine.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/outcome_badge.dart';
import '../widgets/outcome_bars.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  List<ProcedurePrediction>? _results;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final state = context.read<AppState>();
    final draft = state.draftCase;
    if (draft == null) return;
    final results = await state.prediction.predictAllProcedures(draft);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final draft = state.draftCase;

    if (draft == null) {
      return AppShell(
        child: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go back'),
          ),
        ),
      );
    }

    return AppShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Procedure Recommender',
                subtitle: 'Predicted outcomes across all four procedures for this patient.',
                back:
                    BackLink(label: 'Back to result', onTap: () => Navigator.of(context).pop()),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text(
                          'Running the model across all four procedures…',
                          style: TextStyle(fontSize: 12.5, color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Builder(builder: (context) {
                  final best = _results!.first;
                  final reason = LocalPredictionEngine.recommendationReason(best, draft);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      border: Border.all(color: AppColors.brand200),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.brand600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.emoji_events_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('RECOMMENDED PROCEDURE',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gray500)),
                              const SizedBox(height: 2),
                              Text(best.procedure.label,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray900)),
                              const SizedBox(height: 4),
                              Text(reason,
                                  style:
                                      const TextStyle(fontSize: 12.5, color: AppColors.gray600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 1000
                      ? 4
                      : c.maxWidth > 620
                          ? 2
                          : 1;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: cols == 1 ? 1.5 : 0.78,
                    children: List.generate(_results!.length, (i) {
                      final r = _results![i];
                      final recommended = i == 0;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: recommended ? AppColors.brand500 : AppColors.gray200,
                              width: recommended ? 1.4 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (recommended)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.brand600,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Recommended',
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                            Text(r.procedure.label,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gray900)),
                            const SizedBox(height: 8),
                            OutcomeBadge(outcome: r.predictedClass, size: BadgeSize.sm),
                            const SizedBox(height: 14),
                            Expanded(
                              child: OutcomeBars(probabilities: r.probabilities, compact: true),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Utility score',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.gray500)),
                                Text(
                                  r.utility.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: recommended ? AppColors.brand700 : AppColors.gray900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                }),
                const SizedBox(height: 18),
                const Text(
                  'Utility = 3 × P(Excellent) + 2 × P(Good) + 1 × P(Fair) + 0 × P(Poor). '
                  'Predictions are illustrative and not a substitute for clinical judgment.',
                  style: TextStyle(fontSize: 11, color: AppColors.gray400),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
