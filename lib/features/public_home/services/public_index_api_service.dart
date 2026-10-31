import 'package:dio/dio.dart';

import '../../../core/network/admin_api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/public_index_content.dart';

class PublicIndexApiService {
  PublicIndexApiService({Dio? dio}) : _dio = dio ?? AdminApiClient.instance.dio;

  final Dio _dio;

  Future<PublicWebsiteContent> getWebsiteContent() async {
    final response = await _dio.get<Map<String, dynamic>>('/publicindex/content');
    final data = _unwrapData(response.data, 'تعذر تحميل محتوى الموقع');
    return PublicWebsiteContent.fromJson(data);
  }

  Future<RegistrationConfig> getRegistrationConfig(String mode) async {
    final query = mode == 'default' ? '' : '?mode=$mode';
    final response = await _dio.get<Map<String, dynamic>>(
      '/publicindex/registration-config$query',
    );
    final data = _unwrapData(response.data, 'تعذر تحميل إعدادات التسجيل');
    return RegistrationConfig.fromJson(data);
  }

  Future<MasgedBranding> getMasgedSettings() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/adminmasgedsettings');
    final envelope = response.data;
    if (envelope == null) {
      return MasgedBranding.fromJson(null);
    }
    if (envelope['success'] != true) {
      return MasgedBranding.fromJson(null);
    }
    final data = envelope['data'];
    if (data is! Map) {
      return MasgedBranding.fromJson(null);
    }
    return MasgedBranding.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _unwrapData(
    Map<String, dynamic>? envelope,
    String fallbackMessage,
  ) {
    if (envelope == null || envelope['success'] != true || envelope['data'] == null) {
      throw ApiException(
        envelope?['message'] as String? ?? fallbackMessage,
      );
    }
    final data = envelope['data'];
    if (data is! Map) {
      throw ApiException(fallbackMessage);
    }
    return Map<String, dynamic>.from(data);
  }
}
