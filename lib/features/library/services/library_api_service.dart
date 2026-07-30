import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/center_release_model.dart';

class LibraryApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<CenterReleaseModel>> getReleases() async {
    try {
      final response = await _dio.get('/api/centerreleases');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => CenterReleaseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل المكتبة');
    }
  }
}
