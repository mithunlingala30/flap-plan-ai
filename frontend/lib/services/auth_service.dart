import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

/// Wraps Firebase Authentication and keeps a matching profile document in
/// Cloud Firestore at `users/{uid}` so the display name entered at
/// registration is persisted and shown back on the Profile screen.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  /// Registers a new account, sets the Firebase Auth display name, and
  /// writes a profile document to Firestore so the name/role show up
  /// immediately on the Profile screen and dashboard.
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user?.updateDisplayName(name.trim());

    await _usersCol.doc(credential.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role.label,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Live stream of the signed-in user's profile document.
  Stream<UserProfile?> profileStream(String uid) {
    return _usersCol.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromFirestore(uid, doc.data()!);
    });
  }

  Future<void> updateName(String uid, String name) async {
    await _usersCol.doc(uid).update({'name': name.trim()});
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  Future<void> updateRole(String uid, UserRole role) {
    return _usersCol.doc(uid).update({'role': role.label});
  }
}
