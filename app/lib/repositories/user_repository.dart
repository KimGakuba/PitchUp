import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<UserProfile?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromMap(snap.id, snap.data() ?? const {});
    });
  }

  Future<UserProfile?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.id, snap.data() ?? const {});
  }

  Future<List<UserProfile>> getUsers(Iterable<String> uids) async {
    final unique = uids.toSet().toList(growable: false);
    if (unique.isEmpty) return const [];
    final snaps = await Future.wait(
      unique.map((uid) => _users.doc(uid).get()),
    );
    return snaps
        .where((s) => s.exists)
        .map((s) => UserProfile.fromMap(s.id, s.data() ?? const {}))
        .toList(growable: false);
  }

  Stream<List<UserProfile>> watchAllUsers() {
    return _users.snapshots().map((snap) {
      final users = snap.docs
          .map((d) => UserProfile.fromMap(d.id, d.data()))
          .toList(growable: false);
      users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return users;
    });
  }

  Future<void> createProfile({
    required String uid,
    required String name,
    required String phone,
    String? email,
  }) {
    return _users.doc(uid).set({
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email,
      'role': 'player',
      'position': null,
      'reliabilityScore': 100,
      'gamesPlayed': 0,
      'noShows': 0,
      'status': 'active',
      'fcmTokens': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile(
    String uid, {
    required String name,
    String? position,
    String? phone,
  }) {
    return _users.doc(uid).update({
      'name': name.trim(),
      if (position != null) 'position': position.trim().isEmpty ? null : position.trim(),
      if (phone != null) 'phone': phone.trim(),
    });
  }

  Future<void> markSuspended(String uid) {
    return _users.doc(uid).update({'status': 'suspended'});
  }
}
