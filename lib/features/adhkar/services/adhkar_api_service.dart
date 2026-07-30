import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../children/models/student_plan_models.dart';
import '../models/adhkar_category.dart';
import '../models/adhkar_category_summary.dart';

class AdhkarApiService {
  AdhkarApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<PagedResult<AdhkarCategorySummary>> getCategories({
    required int page,
    int pageSize = 20,
    String? search,
    List<int>? ids,
  }) async {
    try {
      final trimmed = search?.trim();
      final response = await _dio.get(
        '/api/adhkar',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (trimmed != null && trimmed.isNotEmpty) 'search': trimmed,
          if (ids != null && ids.isNotEmpty) 'ids': ids.join(','),
        },
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        AdhkarCategorySummary.fromJson,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل الأذكار');
    }
  }

  Future<AdhkarCategory> getCategory(int id) async {
    try {
      final response = await _dio.get('/api/adhkar/$id');
      return AdhkarCategory.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل قسم الأذكار');
    }
  }
}
