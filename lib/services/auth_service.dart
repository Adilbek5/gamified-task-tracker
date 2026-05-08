import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;

  Future<User?> signUp(String email, String password) async {
    final c = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return c.user;
  }

  Future<User?> signIn(String email, String password) async {
    final c = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return c.user;
  }

  Future<void> signOut() async {
    try { await _googleSignIn.signOut(); } catch (_) {}
    await _auth.signOut();
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.emailVerified) return;
      // No ActionCodeSettings — plain call works for all Firebase projects
      await user.sendEmailVerification();
    } catch (e) {
      debugPrint('sendVerificationEmail error: $e');
      // Do not rethrow — user can request resend from UI
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      // reload() fetches fresh state from Firebase server
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {}
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('[GoogleAuth] START: launching account picker');

      debugPrint('[GoogleAuth] Launching account picker');
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('[GoogleAuth] CANCELLED: user dismissed picker');
        return null;
      }

      debugPrint('[GoogleAuth] USER SELECTED: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;

      debugPrint('[GoogleAuth] accessToken: '
          '${googleAuth.accessToken != null ? "OK" : "NULL"}');
      debugPrint('[GoogleAuth] idToken: '
          '${googleAuth.idToken != null ? "OK" : "NULL"}');

      if (googleAuth.idToken == null) {
        throw Exception(
          'Google Sign-In failed: idToken is null. '
          'Check SHA-1 fingerprint in Firebase Console '
          'under Project Settings → Your apps → Android.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('[GoogleAuth] Calling Firebase signInWithCredential');
      final result = await _auth.signInWithCredential(credential);

      debugPrint('[GoogleAuth] SUCCESS: ${result.user?.uid}');
      return result;

    } on FirebaseAuthException catch (e) {
      debugPrint('[GoogleAuth] FirebaseAuthException: '
          '${e.code} — ${e.message}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'This email is already registered with '
            'email/password. Please sign in that way.');
        case 'network-request-failed':
          throw Exception('No internet connection.');
        default:
          throw Exception('Sign-in failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('[GoogleAuth] ERROR: $e');
      rethrow;
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Account exists with different sign-in method';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Sign-in failed. Please try again';
    }
  }
}