import 'patient_case.dart';
export 'patient_case.dart';

class OutcomeProbabilities {
  final double poor;
  final double fair;
  final double good;
  final double excellent;

  const OutcomeProbabilities({
    required this.poor,
    required this.fair,
    required this.good,
    required this.excellent,
  });

  double operator [](HealingOutcome o) {
    switch (o) {
      case HealingOutcome.poor:
        return poor;
      case HealingOutcome.fair:
        return fair;
      case HealingOutcome.good:
        return good;
      case HealingOutcome.excellent:
        return excellent;
    }
  }

  Map<String, dynamic> toJson() => {
        'Poor': poor,
        'Fair': fair,
        'Good': good,
        'Excellent': excellent,
      };

  factory OutcomeProbabilities.fromJson(Map<String, dynamic> j) {
    double read(String k) => (j[k] as num?)?.toDouble() ?? 0.0;
    return OutcomeProbabilities(
      poor: read('Poor'),
      fair: read('Fair'),
      good: read('Good'),
      excellent: read('Excellent'),
    );
  }
}

class FeatureDriver {
  final String feature;
  final double importance; // 0..1
  final bool worse; // true = "worse" direction, false = "better"
  final String detail;

  const FeatureDriver({
    required this.feature,
    required this.importance,
    required this.worse,
    required this.detail,
  });

  Map<String, dynamic> toJson() => {
        'feature': feature,
        'importance': importance,
        'direction': worse ? 'worse' : 'better',
        'detail': detail,
      };

  factory FeatureDriver.fromJson(Map<String, dynamic> j) => FeatureDriver(
        feature: j['feature'] as String,
        importance: (j['importance'] as num).toDouble(),
        worse: (j['direction'] as String) == 'worse',
        detail: j['detail'] as String,
      );
}

class Prediction {
  final OutcomeProbabilities probabilities;
  final HealingOutcome predictedClass;
  final List<FeatureDriver> drivers;
  final double utility;

  /// True when this prediction came from the local offline fallback model
  /// instead of the deployed backend (e.g. the API was unreachable or slow).
  final bool isOffline;

  const Prediction({
    required this.probabilities,
    required this.predictedClass,
    required this.drivers,
    required this.utility,
    this.isOffline = false,
  });

  Map<String, dynamic> toFirestoreJson() => {
        'probabilities': probabilities.toJson(),
        'predictedClass': predictedClass.label,
        'drivers': drivers.map((d) => d.toJson()).toList(),
        'utility': utility,
        'isOffline': isOffline,
      };

  factory Prediction.fromFirestoreJson(Map<String, dynamic> j) => Prediction(
        probabilities: OutcomeProbabilities.fromJson(
            Map<String, dynamic>.from(j['probabilities'] as Map)),
        predictedClass: HealingOutcomeX.fromLabel(j['predictedClass'] as String),
        drivers: (j['drivers'] as List)
            .map((d) => FeatureDriver.fromJson(Map<String, dynamic>.from(d as Map)))
            .toList(),
        utility: (j['utility'] as num).toDouble(),
        isOffline: (j['isOffline'] as bool?) ?? false,
      );
}

class ProcedurePrediction {
  final SurgicalProcedure procedure;
  final OutcomeProbabilities probabilities;
  final HealingOutcome predictedClass;
  final double utility;

  const ProcedurePrediction({
    required this.procedure,
    required this.probabilities,
    required this.predictedClass,
    required this.utility,
  });
}

class SavedCase {
  final String id; // e.g. PT-0231
  final PatientCase patientCase;
  final Prediction prediction;
  final DateTime date;

  const SavedCase({
    required this.id,
    required this.patientCase,
    required this.prediction,
    required this.date,
  });

  Map<String, dynamic> toFirestoreJson() => {
        'id': id,
        'case': patientCase.toFirestoreJson(),
        'prediction': prediction.toFirestoreJson(),
        'date': date.toIso8601String(),
      };

  factory SavedCase.fromFirestoreJson(Map<String, dynamic> j) => SavedCase(
        id: j['id'] as String,
        patientCase:
            PatientCase.fromFirestoreJson(Map<String, dynamic>.from(j['case'] as Map)),
        prediction:
            Prediction.fromFirestoreJson(Map<String, dynamic>.from(j['prediction'] as Map)),
        date: DateTime.parse(j['date'] as String),
      );
}
