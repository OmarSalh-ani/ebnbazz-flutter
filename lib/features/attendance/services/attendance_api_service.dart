import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/attendance_record_model.dart';

class AttendanceApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<AttendanceRecordModel>> getStudentAttendance(
    String studentId, {
    required int year,
    required int month,
  }) async {
    try {
      final response = await _dio.get(
        '/api/attendance/$studentId',
        queryParameters: {
          'year': year,
          'month': month,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final list = data['records'] as List<dynamic>? ?? [];
      return list
          .map((e) => AttendanceRecordModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل سجل الحضور');
    }
  }
}
