import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/unified_api_config.dart';
import '../../features/teacher/auth/providers/auth_providers.dart';
import '../../teacher_core/network/api_client.dart';

class TeacherDeviceTokenApi {
  TeacherDeviceTokenApi(this._client);

  final TeacherApiClient _client;

  Future<void> register({
    required String fcmToken,
    required String platform,
  }) async {
    await _client.postVoid(
      '/api/device/register',
      body: {
        'fcmToken': fcmToken,
        'platform': platform,
      },
    );
  }

  Future<void> unregister({required String fcmToken}) async {
    await _client.dio.delete<void>(
      UnifiedApiConfig.teacherPath('/api/device/unregister'),
      data: {'fcmToken': fcmToken},
    );
  }
}

final teacherDeviceTokenApiProvider = Provider<TeacherDeviceTokenApi>((ref) {
  return TeacherDeviceTokenApi(ref.watch(apiClientProvider));
});
