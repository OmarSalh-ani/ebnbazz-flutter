import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:masged_parent_app/features/teacher/auth/models/auth_user.dart';

class AuthStorage {
  AuthStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _tokenKey = 'teacher_mobile_auth_token';
  static const _userKey = 'teacher_mobile_auth_user';
  static const _savedEmailKey = 'teacher_mobile_saved_login_email';
  static const _savedPasswordKey = 'teacher_mobile_saved_login_password';

  Future<String?> getToken() async => _prefs.getString(_tokenKey);

  Future<AuthUser?> getUser() async {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSession({required String token, required AuthUser user}) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _prefs.setString(_savedEmailKey, email);
    await _prefs.setString(_savedPasswordKey, password);
  }

  Future<({String? email, String? password})> getSavedCredentials() async {
    return (
      email: _prefs.getString(_savedEmailKey),
      password: _prefs.getString(_savedPasswordKey),
    );
  }

  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  Future<void> clearCredentials() async {
    await _prefs.remove(_savedEmailKey);
    await _prefs.remove(_savedPasswordKey);
  }

  Future<void> clear() async {
    await clearSession();
  }
}
