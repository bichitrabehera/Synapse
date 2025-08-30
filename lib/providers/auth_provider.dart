import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/api.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _email;
  bool _loading = true;

  String? get token => _token;
  String? get email => _email;
  bool get loading => _loading;
  bool get loggedIn => _token != null;

  AuthProvider() {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _token = await _storage.read(key: 'token');
    _email = await _storage.read(key: 'email');
    _loading = false;
    notifyListeners();
  }

  /// 🔹 Google Login
  Future<bool> loginWithGoogle() async {
    _loading = true;
    notifyListeners();

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) return false;

      // ✅ Just use Firebase authentication
      final idToken = await firebaseUser.getIdToken(true);

      _token = idToken;
      _email = firebaseUser.email;

      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'email', value: _email);

      return true;
    } catch (e) {
      debugPrint('Google login error: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    await _storage.delete(key: 'token');
    await _storage.delete(key: 'email');
    _token = null;
    _email = null;
    notifyListeners();

    if (context.mounted) {
      context.go('/'); // back to login
    }
  }

  Future<Map<String, String>> authHeader() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken(true) : null;
    return {'Authorization': 'Bearer ${token ?? ''}'};
  }

  String _parseError(String body, [int? status]) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map && parsed['detail'] != null) {
        return parsed['detail'].toString();
      }
    } catch (_) {}
    if (status == 400) return 'Invalid data';
    if (status == 500) return 'Server error. Please try again later.';
    return body;
  }
}
