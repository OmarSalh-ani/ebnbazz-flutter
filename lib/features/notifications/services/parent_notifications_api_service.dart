import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/parent_notification_item.dart';

class ParentNotificationsApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ParentNotificationItem>> fetchNotifications() async {
    try {
      final response = await _dio.get('/api/parent/Notifications');
      final list = response.data as List<dynamic>;
      return list
          .map(
            (e) => ParentNotificationItem.fromJson(
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
