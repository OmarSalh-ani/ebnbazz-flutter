import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/picked_student_photo.dart';
import '../../children/services/students_api_service.dart';
import '../models/public_registration_models.dart';
import '../services/auth_api_service.dart';

// Auth states
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initFuture = _checkAuthStatus();
  }

  final _authApi = AuthApiService();
  late final Future<void> _initFuture;

  /// Set on successful [register] step; OTP screen can read once via [consumeRegisterDebugOtp].
  String? _registerDebugOtp;

  /// Waits for persisted session restore (splash / cold start).
  Future<void> ensureInitialized() => _initFuture;

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
    final token = prefs.getString(AppConstants.keyAuthToken);
    final userJson = prefs.getString(AppConstants.keyUserData);

    // Do not overwrite loading/error from an in-flight login attempt.
    if (state.status != AuthStatus.initial) return;

    if (isLoggedIn && token != null && token.isNotEmpty && userJson != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        ),
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String phone, String password) async {
    state = AuthState(
      status: AuthStatus.loading,
      errorMessage: null,
    );

    try {
      final result = await _authApi.login(phone, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyAuthToken, result.token);
      await prefs.setString(
        AppConstants.keyUserData,
        jsonEncode(result.user.toJson()),
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    } on ApiException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'تعذر الاتصال بالخادم',
      );
      return false;
    }
  }

  /// Student enrollment via [POST /api/auth/student-register]; persists session on success.
  Future<StudentRegistrationResult?> studentRegister(
    SubmitStudentRegistrationPayload payload, {
    List<PickedStudentPhoto?>? pendingPhotos,
    StudentsApiService? studentsApi,
  }) async {
    state = AuthState(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await _authApi.studentRegister(payload);
      final user = UserModel(
        id: result.parentId,
        name: result.fatherName,
        phone: result.phone,
        dialCode: AppConstants.defaultDialCode,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyAuthToken, result.token);
      await prefs.setString(
        AppConstants.keyUserData,
        jsonEncode(user.toJson()),
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

      if (pendingPhotos != null && studentsApi != null) {
        for (var i = 0; i < pendingPhotos.length; i++) {
          final photo = pendingPhotos[i];
          if (photo == null || i >= result.studentIds.length) continue;
          try {
            await studentsApi.uploadStudentPhoto(result.studentIds[i], photo);
          } catch (_) {
            // Photo upload is best-effort after registration.
          }
        }
      }

      return result;
    } on ApiException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'تعذر الاتصال بالخادم',
      );
      return null;
    }
  }

  /// Calls [POST /api/auth/register] to create OTP challenge (SMS integration is server-side).
  Future<bool> register(String name, String phone, String password) async {
    _registerDebugOtp = null;
    state = AuthState(status: AuthStatus.loading, errorMessage: null);

    try {
      final kuwait = AuthApiService.normalizeKuwaitPhone(phone);
      final res = await _authApi.startRegistration(
        fatherName: name.trim(),
        fatherPhoneKuwaitDigits: kuwait,
        password: password,
      );
      _registerDebugOtp = res.debugOtp;
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } on ApiException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'تعذر الاتصال بالخادم',
      );
      return false;
    }
  }

  /// One-time OTP hint shown in SnackBars (development server may return debugOtp in JSON).
  String? consumeRegisterDebugOtp() {
    final v = _registerDebugOtp;
    _registerDebugOtp = null;
    return v;
  }

  /// Completes activation via [POST /api/auth/verify-otp].
  Future<bool> verifyOtp(String otp, String phoneEightDigits) async {
    state = AuthState(status: AuthStatus.loading, errorMessage: null);

    try {
      final kuwait = AuthApiService.normalizeKuwaitPhone(phoneEightDigits);
      final result = await _authApi.verifyRegistrationOtp(
        fatherPhoneKuwaitDigits: kuwait,
        otp: otp.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyAuthToken, result.token);
      await prefs.setString(
        AppConstants.keyUserData,
        jsonEncode(result.user.toJson()),
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    } on ApiException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'تعذر الاتصال بالخادم',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserData);
    await prefs.remove(AppConstants.keyIsLoggedIn);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> deleteAccount(String password) async {
    await AuthApiService().deleteAccount(password);
    await logout();
  }

  Future<void> updateLocalUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyUserData,
      jsonEncode(user.toJson()),
    );
    state = state.copyWith(user: user);
  }

  void clearError() {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
