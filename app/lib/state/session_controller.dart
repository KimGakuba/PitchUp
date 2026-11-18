import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/role.dart';
import '../models/user_profile.dart';
import '../repositories/notification_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';

enum SessionStatus { starting, loading, signedOut, needsProfile, ready, error }

/// Owns authentication and the signed-in profile. The role shown in the UI
/// comes from the Firebase Auth custom claim; the Firestore copy is only a
/// fallback while the claim is loading.
class SessionController extends ChangeNotifier {
  SessionController({
    AuthService? auth,
    UserRepository? users,
    NotificationRepository? notifications,
  }) : _auth = auth ?? AuthService(),
       _users = users ?? UserRepository(),
       _notifications = notifications ?? NotificationRepository();

  final AuthService _auth;
  final UserRepository _users;
  final NotificationRepository _notifications;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  SessionStatus _status = SessionStatus.starting;
  User? _firebaseUser;
  UserProfile? _profile;
  Role _role = Role.player;
  String? _error;
  bool _suspended = false;

  SessionStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserProfile? get profile => _profile;
  Role get role => _role;
  String? get error => _error;
  bool get suspended => _suspended;
  bool get isReady => _status == SessionStatus.ready;
  String? get uid => _firebaseUser?.uid;

  void start() {
    _authSub ??= _auth.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    await _profileSub?.cancel();
    _profileSub = null;
    _firebaseUser = user;
    _profile = null;
    _suspended = false;
    _error = null;

    if (user == null) {
      _status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }

    _status = SessionStatus.loading;
    notifyListeners();

    try {
      final claim = await _auth.readRole(forceRefresh: true);
      _role = Role.parse(claim.role);
      _suspended = claim.status == 'suspended';
    } catch (_) {
      _role = Role.player;
    }

    _profileSub = _users.watchUser(user.uid).listen(
      (profile) {
        _profile = profile;
        _suspended = _suspended || profile?.status == UserStatus.suspended;
        _status = profile == null
            ? SessionStatus.needsProfile
            : SessionStatus.ready;
        notifyListeners();
      },
      onError: (Object error) {
        _error = 'Could not load your profile. Check your connection.';
        _status = SessionStatus.error;
        notifyListeners();
      },
    );

    await _notifications.registerDevice();
  }

  Future<void> signInWithEmail(String email, String password) async {
    _error = null;
    _status = SessionStatus.loading;
    notifyListeners();
    try {
      await _auth.signInWithEmail(email, password);
    } on FirebaseAuthException catch (error) {
      _error = _messageFor(error);
      _status = SessionStatus.signedOut;
      notifyListeners();
    }
  }

  Future<String> requestPhoneCode(String phone) {
    return _auth.requestPhoneCode(phone);
  }

  Future<void> confirmPhoneCode(String verificationId, String code) async {
    _error = null;
    _status = SessionStatus.loading;
    notifyListeners();
    try {
      await _auth.confirmPhoneCode(verificationId, code);
    } on FirebaseAuthException catch (error) {
      _error = _messageFor(error);
      _status = SessionStatus.signedOut;
      notifyListeners();
    }
  }

  Future<void> createProfile({
    required String name,
    required String phone,
  }) async {
    final user = _firebaseUser;
    if (user == null) return;
    await _users.createProfile(
      uid: user.uid,
      name: name,
      phone: phone,
      email: user.email,
    );
    await _auth.refreshIdToken();
    final claim = await _auth.readRole(forceRefresh: true);
    _role = Role.parse(claim.role);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    String? position,
    String? phone,
  }) async {
    final user = _firebaseUser;
    if (user == null) return;
    await _users.updateProfile(
      user.uid,
      name: name,
      position: position,
      phone: phone,
    );
  }

  Future<void> signOut() async {
    await _notifications.unregisterDevice();
    await _auth.signOut();
  }

  Future<void> refreshRole() async {
    final claim = await _auth.readRole(forceRefresh: true);
    _role = Role.parse(claim.role);
    _suspended = claim.status == 'suspended';
    notifyListeners();
  }

  String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'That email address is not valid.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email or password is incorrect.',
      'too-many-requests' => 'Too many attempts. Try again in a moment.',
      'invalid-verification-code' => 'That code is incorrect.',
      'missing-verification-code' => 'Enter the 6-digit code.',
      'network-request-failed' => 'Network error. Check your connection.',
      _ => error.message ?? 'Sign-in failed. Please try again.',
    };
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
