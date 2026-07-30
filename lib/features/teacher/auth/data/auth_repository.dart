import 'package:masged_parent_app/teacher_core/storage/auth_storage.dart';
import '../models/auth_user.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final AuthApi _api;
  final AuthStorage _storage;

  Future<AuthUser?> loadSavedSession() async {
    final user = await _storage.getUser();
    final token = await _storage.getToken();
    if (user == null || token == null || token.isEmpty) return null;

    final session = AuthUser(
      id: user.id,
      name: user.name,
      username: user.username,
      token: token,
      expiresAt: user.expiresAt,
      circleId: user.circleId,
      isAdmin: user.isAdmin,
      isGirlTeacher: user.isGirlTeacher,
    );

    if (!session.isSessionValid) {
      await _storage.clearSession();
      return null;
    }

    return session;
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final user = await _api.login(email: email, password: password);
    await _storage.saveSession(token: user.token, user: user);
    await _storage.saveCredentials(email: email, password: password);
    return user;
  }

  Future<({String? email, String? password})> getSavedCredentials() =>
      _storage.getSavedCredentials();

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _storage.clearSession();
    }
  }

  Future<void> changePassword(String newPassword) async {
    await _api.changePassword(newPassword);
    final saved = await _storage.getSavedCredentials();
    await _storage.clearSession();
    if (saved.email != null && saved.email!.isNotEmpty) {
      await _storage.saveCredentials(
        email: saved.email!,
        password: newPassword,
      );
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      await _api.deleteAccount(password);
    } finally {
      await _storage.clearSession();
    }
  }
}
