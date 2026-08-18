import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/patient_case.dart';
import '../models/prediction.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../services/prediction_service.dart';

/// Central app state: auth session, live profile, live case history, and
/// the in-progress "draft" case as it flows Case Entry -> Result -> Compare.
class AppState extends ChangeNotifier {
  AppState({
    AuthService? authService,
    CaseService? caseService,
    PredictionService? predictionService,
  })  : auth = authService ?? AuthService(),
        cases = caseService ?? CaseService(),
        prediction = predictionService ?? PredictionService() {
    _authSub = auth.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService auth;
  final CaseService cases;
  final PredictionService prediction;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;
  StreamSubscription<List<SavedCase>>? _casesSub;

  User? _user;
  User? get user => _user;
  bool get isSignedIn => _user != null;

  UserProfile? profile;
  List<SavedCase> savedCases = [];
  bool casesLoading = true;

  PatientCase? draftCase;

  void setDraft(PatientCase c) {
    draftCase = c;
    notifyListeners();
  }

  void clearDraft() {
    draftCase = null;
    notifyListeners();
  }

  void _onAuthChanged(User? user) {
    _user = user;
    _profileSub?.cancel();
    _casesSub?.cancel();
    profile = null;
    savedCases = [];

    if (user != null) {
      casesLoading = true;
      _profileSub = auth.profileStream(user.uid).listen((p) {
        profile = p;
        notifyListeners();
      });
      _casesSub = cases.watchCases(user.uid).listen((list) {
        savedCases = list;
        casesLoading = false;
        notifyListeners();
      });
    } else {
      draftCase = null;
    }
    notifyListeners();
  }

  SavedCase? findCase(String id) {
    for (final c in savedCases) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Saves the current draft case. Pass [existingPrediction] when the
  /// Result screen already computed it, to avoid calling the backend twice.
  Future<SavedCase> saveDraftCase({Prediction? existingPrediction}) async {
    final draft = draftCase;
    final u = _user;
    if (draft == null || u == null) {
      throw StateError('No draft case or signed-in user.');
    }
    final pred = existingPrediction ?? await prediction.predict(draft);
    return cases.addCase(
      uid: u.uid,
      patientCase: draft,
      prediction: pred,
      existingCaseCount: savedCases.length,
    );
  }

  Future<void> deleteCase(String id) async {
    final u = _user;
    if (u == null) return;
    await cases.deleteCase(u.uid, id);
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    _casesSub?.cancel();
    prediction.dispose();
    super.dispose();
  }
}
