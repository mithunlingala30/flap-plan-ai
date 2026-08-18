import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient_case.dart';
import '../models/prediction.dart';

/// Persists each user's predicted cases under `users/{uid}/cases/{caseId}`
/// in Cloud Firestore, so their case history follows them across devices.
class CaseService {
  CaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _casesCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('cases');

  /// Live stream of the user's saved cases, newest first.
  Stream<List<SavedCase>> watchCases(String uid) {
    return _casesCol(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SavedCase.fromFirestoreJson(d.data()))
            .toList());
  }

  Future<SavedCase> addCase({
    required String uid,
    required PatientCase patientCase,
    required Prediction prediction,
    required int existingCaseCount,
  }) async {
    final id = 'PT-${(340 + existingCaseCount + 1).toString().padLeft(4, '0')}';
    final saved = SavedCase(
      id: id,
      patientCase: patientCase,
      prediction: prediction,
      date: DateTime.now(),
    );
    await _casesCol(uid).doc(id).set(saved.toFirestoreJson());
    return saved;
  }

  Future<SavedCase?> getCase(String uid, String id) async {
    final doc = await _casesCol(uid).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SavedCase.fromFirestoreJson(doc.data()!);
  }

  Future<void> deleteCase(String uid, String id) async {
    await _casesCol(uid).doc(id).delete();
  }
}

