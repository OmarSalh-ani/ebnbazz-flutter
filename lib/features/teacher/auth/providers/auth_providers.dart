import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/app/providers/app_role_provider.dart';
import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import 'package:masged_parent_app/teacher_core/storage/auth_storage.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../models/auth_user.dart';

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage(ref.watch(sharedPreferencesProvider));
});

final apiClientProvider = Provider<TeacherApiClient>((ref) {
  return TeacherApiClient(ref.watch(authStorageProvider));
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(authStorageProvider),
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    return ref.read(authRepositoryProvider).loadSavedSession();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Login UI handles its own loading spinner; notifier only persists session here.
    final user = await ref.read(authRepositoryProvider).login(
          email: email,
          password: password,
        );
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> changePassword(String newPassword) async {
    await ref.read(authRepositoryProvider).changePassword(newPassword);
    state = const AsyncData(null);
  }

  Future<void> deleteAccount(String password) async {
    await ref.read(authRepositoryProvider).deleteAccount(password);
    state = const AsyncData(null);
  }
}
