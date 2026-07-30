import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import '../models/auth_user.dart';

class AuthApi {
  AuthApi(this._client);

  final TeacherApiClient _client;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    return _client.post<AuthUser>(
      '/api/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
      parseData: (json) => AuthUser.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> logout() => _client.postVoid('/api/auth/logout');

  Future<void> changePassword(String newPassword) => _client.postVoid(
        '/api/auth/change-password',
        body: {'newPassword': newPassword},
      );

  Future<void> deleteAccount(String password) => _client.postVoid(
        '/api/auth/delete-account',
        body: {'password': password},
      );
}
