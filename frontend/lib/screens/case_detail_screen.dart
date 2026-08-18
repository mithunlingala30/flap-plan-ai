import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/local_prediction_engine.dart';
import '../services/report_generator_service.dart';
import '../state/app_state.dart';
import '../widgets/app_shell.dart';
import '../widgets/page_header.dart';
import '../widgets/prediction_detail_widgets.dart';
import '../theme/app_theme.dart';

class CaseDetailScreen extends StatelessWidget {
  final String caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final saved = state.findCase(caseId);

    if (saved == null) {
      return AppShell(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_off_outlined, size: 48, color: AppColors.gray300),
              const SizedBox(height: 16),
              const Text('Case not found.',
                  style: TextStyle(fontSize: 16, color: AppColors.gray500)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final dateFmt = DateFormat('MMMM d, yyyy');

    return AppShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Case ${saved.id}',
                subtitle: 'Predicted ${dateFmt.format(saved.date)}',
                back: BackLink(
                    label: 'Back to dashboard',
                    onTap: () => Navigator.of(context).pop()),
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => ReportGeneratorService.downloadOrPrintCaseReport(
                      context,
                      patientCase: saved.patientCase,
                      prediction: saved.prediction,
                      caseId: saved.id,
                      date: saved.date,
                      clinicianName: state.profile?.name ?? 'Clinician',
                      clinicName: 'Periodontal Surgery Clinic',
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('Download Report'),
                  ),
                ],
              ),
              PredictionDetailBody(
                prediction: saved.prediction,
                patientCase: saved.patientCase,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
