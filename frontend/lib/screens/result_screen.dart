import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prediction.dart';
import '../services/report_generator_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/page_header.dart';
import '../widgets/prediction_detail_widgets.dart';
import 'compare_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Prediction? _prediction;
  bool _loading = true;
  String? _savedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPrediction());
  }

  Future<void> _runPrediction() async {
    final state = context.read<AppState>();
    final draft = state.draftCase;
    if (draft == null) return;
    final pred = await state.prediction.predict(draft);
    if (mounted) {
      setState(() {
        _prediction = pred;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_prediction == null || _saving) return;
    setState(() => _saving = true);
    try {
      final saved =
          await context.read<AppState>().saveDraftCase(existingPrediction: _prediction);
      if (mounted) setState(() => _savedId = saved.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save case: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _downloadReport() async {
    if (_prediction == null) return;
    final state = context.read<AppState>();
    final draft = state.draftCase;
    if (draft == null) return;

    await ReportGeneratorService.downloadOrPrintCaseReport(
      context,
      patientCase: draft,
      prediction: _prediction!,
      caseId: _savedId ?? 'CASE-EVALUATION',
      date: DateTime.now(),
      clinicianName: state.profile?.name ?? 'Clinician',
      clinicName: 'Periodontal Surgery Clinic',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final draft = state.draftCase;

    if (draft == null) {
      return AppShell(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No case in progress.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    return AppShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Prediction Result',
                subtitle: 'Estimated healing outcome for the entered case.',
                back: BackLink(
                    label: 'Back to case entry',
                    onTap: () => Navigator.of(context).pop()),
                actions: [
                  OutlinedButton.icon(
                    onPressed: _prediction == null ? null : _downloadReport,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                    label: const Text('Download Report'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _prediction == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CompareScreen())),
                    icon: const Icon(Icons.compare_arrows, size: 17),
                    label: const Text('Compare procedures'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _prediction == null || _savedId != null ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined, size: 17),
                    label: Text(_savedId != null ? 'Saved $_savedId' : 'Save case'),
                  ),
                ],
              ),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Contacting the prediction model…\nThis can take up to a minute if it is waking up.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Offline warning
                if (_prediction!.isOffline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cloud model unavailable — showing an offline estimate.',
                            style: TextStyle(fontSize: 12, color: AppColors.gray700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Premium prediction body
                PredictionDetailBody(
                  prediction: _prediction!,
                  patientCase: draft,
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
