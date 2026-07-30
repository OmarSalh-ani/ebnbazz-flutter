import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/parent_followup_model.dart';

class ParentFollowupApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<ParentFollowupModel> getFollowup() async {
    try {
      final response = await _dio.get('/api/parent/followup');
      return ParentFollowupModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل بيانات المتابعة');
    }
  }

  Future<ParentFollowupModel> updateFollowup(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/parent/followup', data: data);
      return ParentFollowupModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر حفظ بيانات المتابعة');
    }
  }
}
