import 'package:masged_parent_app/core/config/unified_api_config.dart';
import 'package:masged_parent_app/teacher_core/network/api_client.dart';

import '../models/mrkz_test_models.dart';

class MrkzTestsApi {
  MrkzTestsApi(this._client);

  final TeacherApiClient _client;

  Future<MrkzTestsPage> getTests(int studentId) {
    return _client.get<MrkzTestsPage>(
      '/api/students/$studentId/mrkz-tests',
      parseData: (json) =>
          MrkzTestsPage.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<String> createTest(int studentId, SaveMrkzTestRequest request) {
    return _client.postCommand(
      '/api/students/$studentId/mrkz-tests',
      body: request.toJson(),
    );
  }

  Future<DownloadedBytes> getCertificatePdf(int testId) {
    return _client.getBytes(
      '/api/mrkz-test-certificates/$testId/pdf',
      fallbackFileName:
          'mrkz_certificate_${testId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Uri certificatePdfUri({
    required int testId,
    String? accessToken,
  }) {
    final path = UnifiedApiConfig.teacherPath(
      '/api/mrkz-test-certificates/$testId/pdf',
    );
    return Uri.parse('${UnifiedApiConfig.teacherBaseUrl}$path').replace(
      queryParameters: {
        if (accessToken != null && accessToken.isNotEmpty)
          'access_token': accessToken,
      },
    );
  }
}
