import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/schedule_slot_model.dart';

class ParentScheduleApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ScheduleSlotModel>> fetchSchedule() async {
    try {
      final response = await _dio.get('/api/parent-schedule');
      final list = response.data as List<dynamic>;
      return list
          .map(
            (e) => ScheduleSlotModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException.fromDioException(e);
    }
  }
}
