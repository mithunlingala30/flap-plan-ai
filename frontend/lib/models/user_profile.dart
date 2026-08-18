enum UserRole { admin, clinician, student }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.clinician:
        return 'Clinician';
      case UserRole.student:
        return 'Student';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full access & case management';
      case UserRole.clinician:
        return 'Predict outcomes & recommend procedures';
      case UserRole.student:
        return 'Explore cases in read-only training mode';
    }
  }

  static UserRole fromLabel(String? s) {
    switch (s) {
      case 'Admin':
        return UserRole.admin;
      case 'Student':
        return UserRole.student;
      case 'Clinician':
      default:
        return UserRole.clinician;
    }
  }
}

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  Map<String, dynamic> toFirestoreJson() => {
        'name': name,
        'email': email,
        'role': role.label,
      };

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> j) {
    return UserProfile(
      uid: uid,
      name: (j['name'] as String?) ?? 'User',
      email: (j['email'] as String?) ?? '',
      role: UserRoleX.fromLabel(j['role'] as String?),
      createdAt: null,
    );
  }
}
