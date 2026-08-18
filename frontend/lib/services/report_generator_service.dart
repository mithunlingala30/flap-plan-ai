import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/patient_case.dart';
import '../models/prediction.dart';
import 'local_prediction_engine.dart';

/// Generates professional clinical PDF reports and CSV datasets for
/// periodontal surgery healing outcome predictions.
class ReportGeneratorService {
  static const PdfColor _brandPrimary = PdfColor.fromInt(0xFF0284C7); // brand-600
  static const PdfColor _brandDark = PdfColor.fromInt(0xFF0369A1); // brand-700
  static const PdfColor _brandBg = PdfColor.fromInt(0xFFF0F9FF); // brand-50
  static const PdfColor _gray900 = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _gray700 = PdfColor.fromInt(0xFF334155);
  static const PdfColor _gray500 = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _gray300 = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor _gray100 = PdfColor.fromInt(0xFFF1F5F9);

  static PdfColor _getOutcomeColor(HealingOutcome outcome) {
    switch (outcome) {
      case HealingOutcome.excellent:
        return const PdfColor.fromInt(0xFF10B981); // Emerald
      case HealingOutcome.good:
        return const PdfColor.fromInt(0xFF0284C7); // Sky blue
      case HealingOutcome.fair:
        return const PdfColor.fromInt(0xFFF59E0B); // Amber
      case HealingOutcome.poor:
        return const PdfColor.fromInt(0xFFEF4444); // Rose red
    }
  }

  static PdfColor _getOutcomeBg(HealingOutcome outcome) {
    switch (outcome) {
      case HealingOutcome.excellent:
        return const PdfColor.fromInt(0xFFECFDF5);
      case HealingOutcome.good:
        return const PdfColor.fromInt(0xFFF0F9FF);
      case HealingOutcome.fair:
        return const PdfColor.fromInt(0xFFFFFBEB);
      case HealingOutcome.poor:
        return const PdfColor.fromInt(0xFFFEF2F2);
    }
  }

  /// Opens the native download / print preview modal for a single patient case report.
  static Future<void> downloadOrPrintCaseReport(
    BuildContext context, {
    required PatientCase patientCase,
    required Prediction prediction,
    required String caseId,
    required DateTime date,
    String? clinicianName,
    String? clinicName,
  }) async {
    final pdfBytes = await generateCaseReportPdf(
      patientCase: patientCase,
      prediction: prediction,
      caseId: caseId,
      date: date,
      clinicianName: clinicianName,
      clinicName: clinicName,
    );

    await Printing.layoutPdf(
      name: 'FlapPlan_Report_${caseId.replaceAll(' ', '_')}.pdf',
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  /// Builds raw PDF bytes for a single patient case clinical outcome report.
  static Future<Uint8List> generateCaseReportPdf({
    required PatientCase patientCase,
    required Prediction prediction,
    required String caseId,
    required DateTime date,
    String? clinicianName,
    String? clinicName,
  }) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('MMMM d, yyyy HH:mm');
    final altProcedures = LocalPredictionEngine.predictAllProcedures(patientCase);
    final bestProcedure = altProcedures.first;
    final recommendationReason =
        LocalPredictionEngine.recommendationReason(bestProcedure, patientCase);

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontSemiBold = await PdfGoogleFonts.interSemiBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      fontFallback: [fontRegular],
    );

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(
          caseId: caseId,
          dateFormatted: dateFmt.format(date),
          clinicianName: clinicianName,
          clinicName: clinicName,
          fontBold: fontBold,
          fontRegular: fontRegular,
        ),
        footer: (context) => _buildFooter(context, fontRegular),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Outcome summary banner
          _buildOutcomeBanner(prediction, fontBold, fontSemiBold, fontRegular),
          pw.SizedBox(height: 16),

          // Clinical Inputs Table
          _buildPatientParametersSection(patientCase, fontBold, fontRegular),
          pw.SizedBox(height: 16),

          // Probability Breakdown & Feature Drivers
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 5,
                child: _buildProbabilityTable(
                    prediction.probabilities, fontBold, fontRegular),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                flex: 5,
                child: _buildDriversList(prediction.drivers, fontBold, fontRegular),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Surgical Procedure Comparison & Recommendation
          _buildProcedureComparison(
            currentProcedure: patientCase.procedure,
            procedures: altProcedures,
            bestProcedure: bestProcedure,
            reason: recommendationReason,
            fontBold: fontBold,
            fontSemiBold: fontSemiBold,
            fontRegular: fontRegular,
          ),
          pw.SizedBox(height: 16),

          // Clinical Notes / Disclaimer
          _buildDisclaimer(fontRegular, fontBold),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required String caseId,
    required String dateFormatted,
    String? clinicianName,
    String? clinicName,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _gray300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 22,
                    height: 22,
                    decoration: pw.BoxDecoration(
                      color: _brandPrimary,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '+',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'FlapPlan AI',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _brandDark,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Periodontal Surgical Decision Support Report',
                style: pw.TextStyle(fontSize: 9.5, color: _gray500),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Case ID: $caseId',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _gray900,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Evaluated: $dateFormatted',
                style: pw.TextStyle(fontSize: 8.5, color: _gray500),
              ),
              if (clinicianName != null && clinicianName.isNotEmpty)
                pw.Text(
                  'Clinician: $clinicianName',
                  style: pw.TextStyle(fontSize: 8.5, color: _gray700),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOutcomeBanner(
    Prediction prediction,
    pw.Font fontBold,
    pw.Font fontSemiBold,
    pw.Font fontRegular,
  ) {
    final outcome = prediction.predictedClass;
    final color = _getOutcomeColor(outcome);
    final bg = _getOutcomeBg(outcome);

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1.2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PREDICTED HEALING OUTCOME',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _gray500,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      outcome.label.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  if (prediction.isOffline)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFFEF3C7),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'Offline Mode',
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFF92400E),
                          fontSize: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'CLINICAL UTILITY SCORE',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _gray500,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                prediction.utility.toStringAsFixed(2),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _brandDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientParametersSection(
    PatientCase patientCase,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _gray100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _gray300, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PATIENT CLINICAL PARAMETERS',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: _gray700,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  _tableCell('Age', '${patientCase.age} years'),
                  _tableCell('Sex', patientCase.sex.label),
                  _tableCell('Diabetes Status', patientCase.diabetes.label),
                  _tableCell('Surgical Procedure', patientCase.procedure.label),
                ],
              ),
              pw.TableRow(
                children: [
                  _tableCell('Probing Depth', '${patientCase.probingDepth} mm'),
                  _tableCell('CAL', '${patientCase.clinicalAttachmentLoss} mm'),
                  _tableCell('Gingival Index', '${patientCase.gingivalIndex} / 3'),
                  _tableCell('Plaque Index', '${patientCase.plaqueIndex} / 3'),
                ],
              ),
              pw.TableRow(
                children: [
                  _tableCell('Bleeding on Probing', patientCase.bleedingOnProbing.label),
                  _tableCell('', ''),
                  _tableCell('', ''),
                  _tableCell('', ''),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String title, String val) {
    if (title.isEmpty) return pw.Container();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, right: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 8, color: _gray500)),
          pw.SizedBox(height: 1),
          pw.Text(
            val,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _gray900),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProbabilityTable(
    OutcomeProbabilities probs,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final rows = [
      {'label': 'Excellent', 'p': probs.excellent, 'outcome': HealingOutcome.excellent},
      {'label': 'Good', 'p': probs.good, 'outcome': HealingOutcome.good},
      {'label': 'Fair', 'p': probs.fair, 'outcome': HealingOutcome.fair},
      {'label': 'Poor', 'p': probs.poor, 'outcome': HealingOutcome.poor},
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _gray300, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PROBABILITY BREAKDOWN',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: _gray700,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 8),
          ...rows.map((r) {
            final p = r['p'] as double;
            final outcome = r['outcome'] as HealingOutcome;
            final color = _getOutcomeColor(outcome);
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        r['label'] as String,
                        style: pw.TextStyle(fontSize: 8.5, color: _gray700),
                      ),
                      pw.Text(
                        '${(p * 100).toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _gray900,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    height: 5,
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      color: _gray100,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      width: 210 * p.clamp(0.01, 1.0),
                      height: 5,
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildDriversList(
    List<FeatureDriver> drivers,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _gray300, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'KEY PREDICTIVE DRIVERS',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: _gray700,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 8),
          ...drivers.take(3).map((d) {
            final isNegative = d.worse;
            final color = isNegative
                ? const PdfColor.fromInt(0xFFEF4444)
                : const PdfColor.fromInt(0xFF10B981);
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 2),
                    width: 10,
                    height: 10,
                    decoration: pw.BoxDecoration(
                      color: color,
                      shape: pw.BoxShape.circle,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      isNegative ? '!' : '+',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 6.5),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          d.feature,
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: _gray900,
                          ),
                        ),
                        pw.Text(
                          d.detail,
                          style: pw.TextStyle(fontSize: 7.5, color: _gray500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildProcedureComparison({
    required SurgicalProcedure currentProcedure,
    required List<ProcedurePrediction> procedures,
    required ProcedurePrediction bestProcedure,
    required String reason,
    required pw.Font fontBold,
    required pw.Font fontSemiBold,
    required pw.Font fontRegular,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _brandBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFBAE6FD), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'AI SURGICAL PROCEDURE RECOMMENDER & COMPARISON',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _brandDark,
                  letterSpacing: 0.4,
                ),
              ),
              pw.Text(
                'Recommended: ${bestProcedure.procedure.label}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _brandDark,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            reason,
            style: pw.TextStyle(fontSize: 8.5, color: _gray700),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: _gray300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _gray100),
                children: [
                  _headerCell('Procedure'),
                  _headerCell('Predicted Class'),
                  _headerCell('Good / Exc Prob'),
                  _headerCell('Poor Prob'),
                  _headerCell('Utility Score'),
                ],
              ),
              ...procedures.map((p) {
                final isCurrent = p.procedure == currentProcedure;
                final isBest = p.procedure == bestProcedure.procedure;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isBest ? const PdfColor.fromInt(0xFFF0FDF4) : PdfColors.white,
                  ),
                  children: [
                    _cell(
                      '${p.procedure.label}${isBest ? ' ★ (Best)' : ''}${isCurrent ? ' [Entered]' : ''}',
                      isBold: isBest,
                    ),
                    _cell(p.predictedClass.label, isBold: isBest),
                    _cell('${((p.probabilities.good + p.probabilities.excellent) * 100).toStringAsFixed(0)}%'),
                    _cell('${(p.probabilities.poor * 100).toStringAsFixed(0)}%'),
                    _cell(p.utility.toStringAsFixed(2), isBold: isBest),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _headerCell(String t) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        t,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _gray700),
      ),
    );
  }

  static pw.Widget _cell(String t, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        t,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _gray900,
        ),
      ),
    );
  }

  static pw.Widget _buildDisclaimer(pw.Font fontRegular, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _gray100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CLINICAL NOTICE & DISCLAIMER',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _gray700,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'This machine learning model report is designed strictly as an adjunct decision-support tool. '
            'It does not substitute for comprehensive clinical evaluation, diagnostic radiographs, medical history review, '
            'or the professional judgment of a licensed periodontist or dental practitioner.',
            style: pw.TextStyle(fontSize: 7.5, color: _gray500, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font fontRegular) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _gray300, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FlapPlan AI • Confidential Medical Record',
            style: pw.TextStyle(fontSize: 8, color: _gray500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _gray500),
          ),
        ],
      ),
    );
  }

  /// Exports a list of SavedCases as a CSV formatted string.
  static String generateCsvData(List<SavedCase> cases) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
      'Case ID,Date,Age,Sex,Diabetes,Probing Depth (mm),CAL (mm),Gingival Index,Plaque Index,Bleeding on Probing,Procedure,Predicted Outcome,Utility Score,Poor Prob,Fair Prob,Good Prob,Excellent Prob',
    );

    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    for (final c in cases) {
      final p = c.patientCase;
      final pr = c.prediction;
      buffer.writeln(
        '${c.id},"${dateFmt.format(c.date)}",${p.age},${p.sex.label},${p.diabetes.label},${p.probingDepth},${p.clinicalAttachmentLoss},${p.gingivalIndex},${p.plaqueIndex},${p.bleedingOnProbing.label},"${p.procedure.label}",${pr.predictedClass.label},${pr.utility.toStringAsFixed(2)},${pr.probabilities.poor},${pr.probabilities.fair},${pr.probabilities.good},${pr.probabilities.excellent}',
      );
    }

    return buffer.toString();
  }

  /// Downloads / Prints an aggregate clinical analytics summary PDF report.
  static Future<void> downloadAnalyticsReport(
    BuildContext context, {
    required List<SavedCase> cases,
    String? clinicianName,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

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

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => _buildHeader(
          caseId: 'ANALYTICS-SUMMARY',
          dateFormatted: DateFormat('MMMM d, yyyy').format(DateTime.now()),
          clinicianName: clinicianName,
          clinicName: 'Clinical Analytics Department',
          fontBold: fontBold,
          fontRegular: fontRegular,
        ),
        footer: (ctx) => _buildFooter(ctx, fontRegular),
        build: (ctx) => [
          pw.SizedBox(height: 14),
          pw.Text(
            'PERIODONTAL CLINICAL OUTCOMES & PRACTICE ANALYTICS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _brandDark,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Aggregate performance analysis across $total evaluated patient cases.',
            style: pw.TextStyle(fontSize: 9.5, color: _gray500),
          ),
          pw.SizedBox(height: 16),

          // High level stats
          pw.Row(
            children: [
              _statBox('Total Cases', '$total', _brandDark),
              pw.SizedBox(width: 10),
              _statBox(
                'Favorable (Good/Exc)',
                total == 0 ? '0%' : '${(goodExc / total * 100).toStringAsFixed(1)}%',
                const PdfColor.fromInt(0xFF10B981),
              ),
              pw.SizedBox(width: 10),
              _statBox(
                'High Risk (Poor)',
                total == 0 ? '0%' : '${(poor / total * 100).toStringAsFixed(1)}%',
                const PdfColor.fromInt(0xFFEF4444),
              ),
              pw.SizedBox(width: 10),
              _statBox('Average Utility', avgUtility.toStringAsFixed(2), _gray900),
            ],
          ),
          pw.SizedBox(height: 18),

          // Procedure breakdown
          pw.Text(
            'PROCEDURE OUTCOME DISTRIBUTION',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _gray700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: _gray300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _gray100),
                children: [
                  _headerCell('Procedure'),
                  _headerCell('Cases Evaluated'),
                  _headerCell('Good / Exc Rate'),
                  _headerCell('Poor Rate'),
                  _headerCell('Mean Utility'),
                ],
              ),
              ...kProcedures.map((proc) {
                final pCases = cases.where((c) => c.patientCase.procedure == proc).toList();
                final pTotal = pCases.length;
                final pGoodExc = pCases
                    .where((c) =>
                        c.prediction.predictedClass == HealingOutcome.good ||
                        c.prediction.predictedClass == HealingOutcome.excellent)
                    .length;
                final pPoor = pCases
                    .where((c) => c.prediction.predictedClass == HealingOutcome.poor)
                    .length;
                final pMeanUtil = pTotal == 0
                    ? 0.0
                    : pCases.map((c) => c.prediction.utility).reduce((a, b) => a + b) / pTotal;

                return pw.TableRow(
                  children: [
                    _cell(proc.label, isBold: true),
                    _cell('$pTotal'),
                    _cell(pTotal == 0 ? '—' : '${(pGoodExc / pTotal * 100).toStringAsFixed(0)}%'),
                    _cell(pTotal == 0 ? '—' : '${(pPoor / pTotal * 100).toStringAsFixed(0)}%'),
                    _cell(pTotal == 0 ? '—' : pMeanUtil.toStringAsFixed(2)),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 18),

          _buildDisclaimer(fontRegular, fontBold),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'FlapPlan_Analytics_Summary.pdf',
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _statBox(String title, String val, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _gray100,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _gray300, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 7.5, color: _gray500)),
            pw.SizedBox(height: 4),
            pw.Text(
              val,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
