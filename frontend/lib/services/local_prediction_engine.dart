import 'dart:math';

import '../models/patient_case.dart';
import '../models/prediction.dart';

/// A deterministic, explainable scoring model that mirrors the original
/// web app's `src/lib/prediction.ts`. It is used:
///   1. As an offline fallback whenever the deployed backend model at
///      https://backend-hhbp.onrender.com is unreachable or slow.
///   2. To always compute the "top drivers" explanation panel, since the
///      driver breakdown is a clinical heuristic independent of whichever
///      model produced the class probabilities.
class LocalPredictionEngine {
  static const Map<SurgicalProcedure, double> _procedureModifier = {
    SurgicalProcedure.gtr: 0.9,
    SurgicalProcedure.flapSurgery: 0.4,
    SurgicalProcedure.laserSurgery: 0.2,
    SurgicalProcedure.openDebridement: -0.5,
  };

  static const Map<SurgicalProcedure, double> _procedureDepthAffinity = {
    SurgicalProcedure.gtr: 0.35,
    SurgicalProcedure.flapSurgery: 0.2,
    SurgicalProcedure.laserSurgery: 0.05,
    SurgicalProcedure.openDebridement: -0.2,
  };

  static double _clamp(double n, double min, double max) =>
      n < min ? min : (n > max ? max : n);

  static double healthScore(PatientCase c) {
    double s = 2.2;
    s -= (c.probingDepth - 3) * 0.32;
    s -= c.clinicalAttachmentLoss * 0.34;
    s -= c.gingivalIndex * 0.55;
    s -= c.plaqueIndex * 0.4;
    if (c.bleedingOnProbing == YesNo.yes) s -= 0.7;
    if (c.diabetes == YesNo.yes) s -= 0.8;
    if (c.age > 55) s -= (c.age - 55) * 0.015;

    final depthSeverity = _clamp((c.probingDepth - 4) / 6, 0, 1);
    s += _procedureModifier[c.procedure]!;
    s += _procedureDepthAffinity[c.procedure]! * depthSeverity;
    return s;
  }

  static OutcomeProbabilities scoreToProbabilities(double score) {
    final anchors = <HealingOutcome, double>{
      HealingOutcome.poor: -1.5,
      HealingOutcome.fair: 0.2,
      HealingOutcome.good: 1.7,
      HealingOutcome.excellent: 3.2,
    };
    const temp = 1.15;
    final logits = kOutcomes.map((o) {
      final d = score - anchors[o]!;
      return -(d * d) / (2 * temp * temp);
    }).toList();
    final maxL = logits.reduce(max);
    final exps = logits.map((l) => exp(l - maxL)).toList();
    final sum = exps.reduce((a, b) => a + b);
    final probs = exps.map((e) => e / sum).toList();
    return OutcomeProbabilities(
      poor: probs[0],
      fair: probs[1],
      good: probs[2],
      excellent: probs[3],
    );
  }

  static double utilityScore(OutcomeProbabilities p) =>
      3 * p.excellent + 2 * p.good + 1 * p.fair + 0 * p.poor;

  static HealingOutcome argmaxOutcome(OutcomeProbabilities p) {
    var best = HealingOutcome.poor;
    var bestV = -double.infinity;
    for (final o in kOutcomes) {
      if (p[o] > bestV) {
        bestV = p[o];
        best = o;
      }
    }
    return best;
  }

  static List<FeatureDriver> computeDrivers(PatientCase c) {
    final raw = <FeatureDriver>[];

    final ppdMag = _clamp((c.probingDepth - 3) / 9, 0, 1);
    raw.add(FeatureDriver(
      feature: 'Probing Depth',
      importance: ppdMag * 0.9,
      worse: true,
      detail: '${c.probingDepth.toStringAsFixed(1)} mm pocket depth',
    ));

    final calMag = _clamp(c.clinicalAttachmentLoss / 10, 0, 1);
    raw.add(FeatureDriver(
      feature: 'Clinical Attachment Loss',
      importance: calMag * 0.95,
      worse: true,
      detail:
          '${c.clinicalAttachmentLoss.toStringAsFixed(1)} mm attachment loss',
    ));

    raw.add(FeatureDriver(
      feature: 'Bleeding on Probing',
      importance: c.bleedingOnProbing == YesNo.yes ? 0.7 : 0.15,
      worse: c.bleedingOnProbing == YesNo.yes,
      detail: c.bleedingOnProbing == YesNo.yes
          ? 'Active bleeding present'
          : 'No bleeding',
    ));

    raw.add(FeatureDriver(
      feature: 'Diabetes Status',
      importance: c.diabetes == YesNo.yes ? 0.75 : 0.1,
      worse: c.diabetes == YesNo.yes,
      detail: c.diabetes == YesNo.yes ? 'Impaired healing risk' : 'Non-diabetic',
    ));

    raw.add(FeatureDriver(
      feature: 'Gingival Index',
      importance: _clamp(c.gingivalIndex / 3, 0, 1) * 0.65,
      worse: c.gingivalIndex > 1.2,
      detail: 'GI ${c.gingivalIndex.toStringAsFixed(2)}',
    ));

    raw.add(FeatureDriver(
      feature: 'Plaque Index',
      importance: _clamp(c.plaqueIndex / 3, 0, 1) * 0.55,
      worse: c.plaqueIndex > 1.2,
      detail: 'PI ${c.plaqueIndex.toStringAsFixed(2)}',
    ));

    raw.sort((a, b) => b.importance.compareTo(a.importance));
    return raw.take(3).toList();
  }

  static Prediction predict(PatientCase c, {bool isOffline = false}) {
    final probabilities = scoreToProbabilities(healthScore(c));
    return Prediction(
      probabilities: probabilities,
      predictedClass: argmaxOutcome(probabilities),
      drivers: computeDrivers(c),
      utility: utilityScore(probabilities),
      isOffline: isOffline,
    );
  }

  static List<ProcedurePrediction> predictAllProcedures(PatientCase c) {
    final results = kProcedures.map((procedure) {
      final probabilities =
          scoreToProbabilities(healthScore(c.copyWith(procedure: procedure)));
      return ProcedurePrediction(
        procedure: procedure,
        probabilities: probabilities,
        predictedClass: argmaxOutcome(probabilities),
        utility: utilityScore(probabilities),
      );
    }).toList();
    results.sort((a, b) => b.utility.compareTo(a.utility));
    return results;
  }

  static String recommendationReason(ProcedurePrediction best, PatientCase c) {
    final attach = c.clinicalAttachmentLoss >= 5
        ? 'severe attachment loss'
        : c.clinicalAttachmentLoss >= 3
            ? 'moderate attachment loss'
            : 'mild attachment loss';
    final dia = c.diabetes == YesNo.yes ? 'diabetes present' : 'no diabetes';
    final goodExc =
        (best.probabilities.excellent + best.probabilities.good) * 100;
    final pctText = goodExc > 0 ? goodExc.round() : 0;
    return 'Best expected healing given $attach and $dia. '
        'Projected utility ${best.utility.toStringAsFixed(2)} with '
        '$pctText% chance of Good/Excellent recovery.';
  }
}
