import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/public_registration_models.dart';
import '../models/user_model.dart';

class LoginResult {
  final String token;
  final UserModel user;

  LoginResult({required this.token, required this.user});
}

/// Response from [POST /api/auth/register] (may include OTP in development).
class RegistrationStartResponse {
  final String message;
  final String? debugOtp;

  RegistrationStartResponse({
    required this.message,
    this.debugOtp,
  });
}

class AuthApiService {
  final Dio _dio = ApiClient.instance.dio;

  static String normalizeKuwaitPhone(String eightDigitLocal) {
    final d = eightDigitLocal.replaceAll(RegExp(r'\D'), '');
    if (d.length != 8) return eightDigitLocal;
    return '965$d';
  }

  Future<LoginResult> login(String phone, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'fatherPhone': phone,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = (data['token'] ?? data['Token'])?.toString() ?? '';
      if (token.isEmpty) {
        throw ApiException('استجابة غير صالحة من الخادم');
      }

      final user = UserModel(
        id: (data['parentId'] ?? data['ParentId'] ?? '').toString(),
        name: (data['fatherName'] ?? data['FatherName'])?.toString() ?? '',
        phone: (data['phone'] ?? data['Phone'])?.toString() ?? phone,
        dialCode: AppConstants.defaultDialCode,
      );

      return LoginResult(token: token, user: user);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioException(e);
    }
  }

  Future<RegistrationStartResponse> startRegistration({
    required String fatherName,
    required String fatherPhoneKuwaitDigits,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'fatherName': fatherName,
          'fatherPhone': fatherPhoneKuwaitDigits,
          'password': password,
        },
      );
      final data = response.data;
      final map = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
      return RegistrationStartResponse(
        message:
            map['message']?.toString() ?? 'تم إرسال رمز التحقق',
        debugOtp: map['debugOtp']?.toString(),
      );
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioException(e);
    }
  }

  Future<StudentRegistrationResult> studentRegister(
    SubmitStudentRegistrationPayload payload,
  ) async {
    try {
      final response = await _dio.post(
        '/api/auth/student-register',
        data: payload.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      final token = (data['token'] ?? data['Token'])?.toString() ?? '';
      if (token.isEmpty) {
        throw ApiException('استجابة غير صالحة من الخادم');
      }

      final phone = (data['phone'] ?? data['Phone'])?.toString() ?? '';
      final rawIds = data['studentIds'] ?? data['StudentIds'];
      final studentIds = rawIds is List
          ? rawIds.map((e) => e.toString()).toList()
          : <String>[];

      return StudentRegistrationResult(
        token: token,
        parentId: (data['parentId'] ?? data['ParentId'] ?? '').toString(),
        fatherName: (data['fatherName'] ?? data['FatherName'])?.toString() ?? '',
        phone: phone,
        studentIds: studentIds,
      );
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioException(e);
    }
  }

  Future<LoginResult> verifyRegistrationOtp({
    required String fatherPhoneKuwaitDigits,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/verify-otp',
        data: {
          'fatherPhone': fatherPhoneKuwaitDigits,
          'otp': otp,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = (data['token'] ?? data['Token'])?.toString() ?? '';
      if (token.isEmpty) {
        throw ApiException('استجابة غير صالحة من الخادم');
      }

      final user = UserModel(
        id: (data['parentId'] ?? data['ParentId'] ?? '').toString(),
        name: (data['fatherName'] ?? data['FatherName'])?.toString() ?? '',
        phone: (data['phone'] ?? data['Phone'])?.toString() ?? '',
        dialCode: AppConstants.defaultDialCode,
      );

      return LoginResult(token: token, user: user);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioException(e);
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      await _dio.post(
        '/api/auth/delete-account',
        data: {'password': password},
      );
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioException(e);
    }
  }
}
