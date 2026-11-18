import 'role.dart';

enum UserStatus { active, suspended }

/// Mirrors the `users/{uid}` Firestore document. `role` is also set as a
/// Firebase Auth custom claim by a Cloud Function — the Firestore field is
/// never trusted alone for authorization.
class UserProfile {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final Role role;
  final String? position;
  final double reliabilityScore; // 0-100
  final int gamesPlayed;
  final int noShows;
  final UserStatus status;
  final List<String> fcmTokens;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.position,
    required this.reliabilityScore,
    required this.gamesPlayed,
    required this.noShows,
    this.status = UserStatus.active,
    this.fcmTokens = const [],
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: (map['name'] ?? 'Player') as String,
      phone: (map['phone'] ?? '') as String,
      email: map['email'] as String?,
      role: Role.parse(map['role']),
      position: map['position'] as String?,
      reliabilityScore:
          (map['reliabilityScore'] as num?)?.toDouble() ?? 100,
      gamesPlayed: (map['gamesPlayed'] as num?)?.toInt() ?? 0,
      noShows: (map['noShows'] as num?)?.toInt() ?? 0,
      status: UserStatus.values.firstWhere(
        (s) => s.name == (map['status']?.toString() ?? 'active'),
        orElse: () => UserStatus.active,
      ),
      fcmTokens: (map['fcmTokens'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }

  int get attended => gamesPlayed;

  UserProfile copyWith({String? name, String? position, String? phone}) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email,
      role: role,
      position: position ?? this.position,
      reliabilityScore: reliabilityScore,
      gamesPlayed: gamesPlayed,
      noShows: noShows,
      status: status,
      fcmTokens: fcmTokens,
    );
  }
}
