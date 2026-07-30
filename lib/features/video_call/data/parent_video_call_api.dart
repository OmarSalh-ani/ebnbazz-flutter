import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/video_call_models.dart';

/// Parent JWT join — REST returns bare JSON [ParentVideoCallJoinResult], not GlobalResponse envelope.
class ParentVideoCallApi {
  final Dio _dio = ApiClient.instance.dio;

  Future<int?> findActiveMeeting({
    required int teacherId,
    required int studentId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/parent/VideoCall/active',
        queryParameters: {
          'teacherId': teacherId,
          'studentId': studentId,
        },
      );
      final id = response.data?['meetingId'];
      if (id is int) return id;
      if (id is num) return id.toInt();
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  Future<ParentVideoCallJoinResult> join(int meetingId, {int? studentId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/parent/VideoCall/$meetingId/join',
        queryParameters: studentId != null ? {'studentId': studentId} : null,
      );
      final data = response.data;
      if (data == null) {
        throw ApiException('استجابة فارغة من الخادم');
      }
      return ParentVideoCallJoinResult.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
