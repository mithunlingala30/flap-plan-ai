import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/patient_case.dart';
import '../models/prediction.dart';
import 'local_prediction_engine.dart';

/// Talks to the deployed, data-trained backend model and falls back to the
/// local offline heuristic (see [LocalPredictionEngine]) whenever the API
/// is unreachable, cold-starting, or returns something we can't parse.
///
/// IMPORTANT: Render free-tier services spin down when idle and can take
/// 20-50s to "wake up" on the first request after inactivity, so the
/// timeout below is intentionally generous.
class PredictionService {
  PredictionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Base URL of the deployed, data-trained model.
  static const String baseUrl = 'https://backend-hhbp.onrender.com';

  /// Endpoint that accepts a single case and returns a prediction.
  /// Change this if your FastAPI/Flask route is named differently
  /// (e.g. '/predict', '/api/predict', '/predict-outcome').
  static const String predictPath = '/predict';

  static const Duration _timeout = Duration(seconds: 45);

  Uri get _predictUri => Uri.parse('$baseUrl$predictPath');

  /// Predicts the outcome for a single patient case + chosen procedure.
  /// Always tries the deployed model first; falls back to the local
  /// deterministic model (flagged via [Prediction.isOffline]) on failure.
  Future<Prediction> predict(PatientCase c) async {
    try {
      final response = await _client
          .post(
            _predictUri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(c.toApiJson()),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
            'Backend returned ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      final parsed = _parseBackendResponse(decoded, c);
      if (parsed != null) return parsed;

      throw const FormatException('Unrecognized backend response shape');
    } catch (_) {
      // Network error, timeout, cold start, or unparseable response.
      // Gracefully degrade to the offline model so the app never breaks.
      return LocalPredictionEngine.predict(c, isOffline: true);
    }
  }

  /// Predicts the outcome for the case across all four surgical procedures,
  /// so the app can recommend the best one (mirrors predictAllProcedures
  /// from the original web app). Calls the backend once per procedure.
  Future<List<ProcedurePrediction>> predictAllProcedures(
      PatientCase c) async {
    final results = <ProcedurePrediction>[];
    for (final procedure in kProcedures) {
      final prediction = await predict(c.copyWith(procedure: procedure));
      results.add(ProcedurePrediction(
        procedure: procedure,
        probabilities: prediction.probabilities,
        predictedClass: prediction.predictedClass,
        utility: prediction.utility,
      ));
    }
    results.sort((a, b) => b.utility.compareTo(a.utility));
    return results;
  }

  /// Tries several common response shapes so this works with most simple
  /// ML backends without you needing to change the Flutter code:
  ///
  /// 1. { "probabilities": {"Poor":0.1,"Fair":0.2,"Good":0.5,"Excellent":0.2},
  ///      "predicted_class": "Good", "drivers": [...] (optional) }
  /// 2. { "Poor": 0.1, "Fair": 0.2, "Good": 0.5, "Excellent": 0.2 }
  /// 3. { "probabilities": [0.1, 0.2, 0.5, 0.2] }  // order: Poor,Fair,Good,Excellent
  /// 4. { "prediction": "Good", "confidence": 0.72 } // single-label classifier
  /// 5. { "prediction": "Good", "probability": 0.72 }
  ///
  /// Drivers (top contributing factors) are always computed locally via
  /// [LocalPredictionEngine.computeDrivers] since they are a clinical
  /// explainability layer independent of the model's raw output, unless
  /// the backend explicitly returns its own `drivers` array.
  Prediction? _parseBackendResponse(dynamic decoded, PatientCase c) {
    if (decoded is! Map<String, dynamic>) return null;

    OutcomeProbabilities? probs;

    // Shape 1 & nested probabilities dict.
    final probField = decoded['probabilities'] ?? decoded['probability'];
    if (probField is Map) {
      final m = Map<String, dynamic>.from(probField);
      if (m.containsKey('Poor') || m.containsKey('poor')) {
        probs = OutcomeProbabilities(
          poor: _readNum(m, ['Poor', 'poor']),
          fair: _readNum(m, ['Fair', 'fair']),
          good: _readNum(m, ['Good', 'good']),
          excellent: _readNum(m, ['Excellent', 'excellent']),
        );
      }
    } else if (probField is List && probField.length == 4) {
      probs = OutcomeProbabilities(
        poor: (probField[0] as num).toDouble(),
        fair: (probField[1] as num).toDouble(),
        good: (probField[2] as num).toDouble(),
        excellent: (probField[3] as num).toDouble(),
      );
    }

    // Shape 2: probabilities directly at the top level.
    if (probs == null &&
        (decoded.containsKey('Poor') || decoded.containsKey('poor'))) {
      probs = OutcomeProbabilities(
        poor: _readNum(decoded, ['Poor', 'poor']),
        fair: _readNum(decoded, ['Fair', 'fair']),
        good: _readNum(decoded, ['Good', 'good']),
        excellent: _readNum(decoded, ['Excellent', 'excellent']),
      );
    }

    // Shape 4 & 5: single predicted label + confidence only.
    if (probs == null) {
      final label = decoded['predicted_class'] ??
          decoded['prediction'] ??
          decoded['class'] ??
          decoded['label'];
      if (label is String) {
        final confidence = (decoded['confidence'] ?? decoded['probability'])
                is num
            ? (decoded['confidence'] ?? decoded['probability'] as num)
                .toDouble()
            : 0.7;
        probs = _syntheticDistribution(
            HealingOutcomeX.fromLabel(label), confidence.clamp(0.34, 0.97));
      }
    }

    if (probs == null) return null;

    final predictedClassLabel = decoded['predicted_class'] ??
        decoded['prediction'] ??
        decoded['class'] ??
        decoded['label'];
    final predictedClass = predictedClassLabel is String
        ? HealingOutcomeX.fromLabel(predictedClassLabel)
        : LocalPredictionEngine.argmaxOutcome(probs);

    List<FeatureDriver> drivers;
    final driversField = decoded['drivers'] ?? decoded['top_drivers'];
    if (driversField is List && driversField.isNotEmpty) {
      try {
        drivers = driversField
            .map((d) => FeatureDriver.fromJson(Map<String, dynamic>.from(d)))
            .toList();
      } catch (_) {
        drivers = LocalPredictionEngine.computeDrivers(c);
      }
    } else {
      drivers = LocalPredictionEngine.computeDrivers(c);
    }

    return Prediction(
      probabilities: probs,
      predictedClass: predictedClass,
      drivers: drivers,
      utility: LocalPredictionEngine.utilityScore(probs),
      isOffline: false,
    );
  }

  double _readNum(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toDouble();
    }
    return 0.0;
  }

  /// Builds a soft distribution centered on [predicted] with [confidence]
  /// mass, spreading the remainder over neighboring ordinal classes.
  OutcomeProbabilities _syntheticDistribution(
      HealingOutcome predicted, double confidence) {
    final idx = kOutcomes.indexOf(predicted);
    final remaining = 1 - confidence;
    final weights = List<double>.filled(4, 0);
    weights[idx] = confidence;
    final neighbors = <int>[];
    if (idx - 1 >= 0) neighbors.add(idx - 1);
    if (idx + 1 < 4) neighbors.add(idx + 1);
    if (neighbors.isEmpty) {
      weights[idx] += remaining;
    } else {
      final share = remaining / neighbors.length;
      for (final n in neighbors) {
        weights[n] += share;
      }
    }
    return OutcomeProbabilities(
      poor: weights[0],
      fair: weights[1],
      good: weights[2],
      excellent: weights[3],
    );
  }

  void dispose() => _client.close();
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}
