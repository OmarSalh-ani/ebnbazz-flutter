import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;

  static ApiException fromResponse(int? statusCode, dynamic data) {
    if (statusCode == 401) {
      return ApiException('رقم الجوال أو كلمة المرور غير صحيحة', statusCode: 401);
    }
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString(), statusCode: statusCode);
    }
    return ApiException('حدث خطأ، يرجى المحاولة لاحقاً', statusCode: statusCode);
  }

  static ApiException fromDioException(DioException error) {
    if (error.response != null) {
      return fromResponse(error.response?.statusCode, error.response?.data);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('انتهت مهلة الاتصال، تحقق من الشبكة وحاول مرة أخرى');
      case DioExceptionType.connectionError:
        return ApiException(
          'تعذر الاتصال بالخادم. تأكد أن التطبيق والخادم على نفس الشبكة وأن API يعمل',
        );
      default:
        return ApiException('تعذر الاتصال بالخادم');
    }
  }
}
