import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Auth used by [SessionController]. Phone OTP
/// works against the Auth emulator (any code shown there is accepted) and
/// against real Firebase in production.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String> requestPhoneCode(String phoneNumber) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );
    return completer.future;
  }

  Future<UserCredential> confirmPhoneCode(
    String verificationId,
    String smsCode,
  ) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<RoleClaim> readRole({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return const RoleClaim(role: 'player', status: 'active');
    final token = await user.getIdTokenResult(forceRefresh);
    final role = token.claims?['role'];
    final status = token.claims?['status'];
    return RoleClaim(
      role: role is String ? role : 'player',
      status: status is String ? status : 'active',
    );
  }

  Future<void> refreshIdToken() async {
    await _auth.currentUser?.getIdToken(true);
  }
}

class RoleClaim {
  const RoleClaim({required this.role, required this.status});
  final String role;
  final String status;
}
