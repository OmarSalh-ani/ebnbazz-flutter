import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/news_model.dart';

class NewsApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<NewsModel>> getNews() async {
    try {
      final response = await _dio.get('/api/masgednews');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل الأخبار');
    }
  }
}
