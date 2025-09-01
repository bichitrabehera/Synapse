import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  User? _user;
  bool _loading = true;

  bool get loading => _loading;
  bool get loggedIn => _user != null;
  String? get email => _user?.email;

  // 🔹 Configure GoogleSignIn with your Web Client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        "670967196705-o10lt1tmdom0attqg51j68dd7v0ojabe.apps.googleusercontent.com",
    // ⬅️ replace this
  );

  AuthProvider() {
    _init();
  }

  void _init() {
    // 🔹 Listen to Firebase authentication state
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _user = user;
      _loading = false;

      if (user != null) {
        final idToken = await user.getIdToken(true);
        await _storage.write(key: 'token', value: idToken);
        await _storage.write(key: 'email', value: user.email ?? '');
      } else {
        await _storage.delete(key: 'token');
        await _storage.delete(key: 'email');
      }

      notifyListeners(); // 🔑 Triggers GoRouter redirect
    });
  }

  /// 🔹 Google Sign-In

  Future<bool> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) return false;

      // ✅ Firebase ID token
      final idToken = await user.getIdToken(true);

      // ✅ Correct backend URL
      final response = await http.post(
        Uri.parse("https://tapcard-backend.onrender.com/api/auth/google-login"),
        headers: {
          "Authorization": "Bearer $idToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        debugPrint("🎉 Synced with backend: ${response.body}");
        return true;
      } else {
        debugPrint(
            "❌ Backend error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Google login error: $e");
      return false;
    }
  }

  /// 🔹 Logout
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
    // authStateChanges listener will clear storage & notify
  }

  /// 🔹 Auth Header for API calls
  Future<Map<String, String>> authHeader() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken(true) : null;
    return {'Authorization': 'Bearer ${token ?? ''}'};
  }

  String parseError(String body, [int? status]) {
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
