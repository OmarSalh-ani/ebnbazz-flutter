import 'package:dio/dio.dart';

import '../../../core/network/admin_api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/public_registration_models.dart';

class PublicRegistrationApiService {
  final Dio _dio = AdminApiClient.instance.dio;

  Future<PublicRegistrationConfig> getRegistrationConfig({
    String mode = 'default',
  }) async {
    try {
      final query = mode == 'default' ? '' : '?mode=$mode';
      final response = await _dio.get('/publicindex/registration-config$query');
      final envelope = ApiResponseDto.fromJson(
        response.data as Map<String, dynamic>,
        PublicRegistrationConfig.fromJson,
      );
      if (!envelope.success || envelope.data == null) {
        throw ApiException(envelope.message.isNotEmpty
            ? envelope.message
            : 'تعذر تحميل إعدادات التسجيل');
      }
      return envelope.data!;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل إعدادات التسجيل');
    }
  }

  Future<List<CountryDialEntry>> getCountryDialCodes() async {
    try {
      final response = await _dio.get('/publiccountrydialcodes');
      final list = (response.data as Map<String, dynamic>)['data']
              as List<dynamic>? ??
          [];
      return list
          .map((e) => CountryDialEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل رموز الدول');
    }
  }
}
