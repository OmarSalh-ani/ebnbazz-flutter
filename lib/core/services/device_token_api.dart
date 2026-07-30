import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';

class DeviceTokenApi {
  DeviceTokenApi({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<void> register({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      await _dio.post(
        '/api/parent/device/register',
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
        },
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioException(e);
    }
  }

  Future<void> unregister({required String fcmToken}) async {
    try {
      await _dio.delete(
        '/api/parent/device/unregister',
        data: {'fcmToken': fcmToken},
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioException(e);
    }
  }
}
