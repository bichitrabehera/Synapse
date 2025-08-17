import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';   // ✅ import go_router
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

  Future<void> logout(BuildContext context) async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'email');
    _token = null;
    _email = null;
    notifyListeners();

    // ✅ use GoRouter to redirect to login
    if (context.mounted) {
      context.go('/'); // or your login route path
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await Api.postForm('/auth/login', {
        'username': email, // backend expects "username"
        'password': password,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['access_token'] ?? data['token'] ?? data['access'];
        _email = email;
        await _storage.write(key: 'token', value: _token);
        await _storage.write(key: 'email', value: _email);
        return true;
      } else {
        final errBody = _parseError(res.body);
        throw Exception(errBody);
      }
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(Map<String, dynamic> payload) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await Api.post('/auth/register', payload);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return await login(payload['email'] as String, payload['password'] as String);
      } else {
        final errBody = _parseError(res.body, res.statusCode);
        throw Exception(errBody);
      }
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Map<String, String> authHeader() => {'Authorization': 'Bearer ${_token ?? ''}'};

  String _parseError(String body, [int? status]) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map && parsed['detail'] != null) {
        return parsed['detail'].toString();
      }
    } catch (_) {}
    if (status == 400) return 'Invalid registration data';
    if (status == 500) return 'Server error. Please try again later.';
    return body;
  }
}
