import 'package:masged_parent_app/core/config/unified_api_config.dart';
import 'package:masged_parent_app/teacher_core/network/api_client.dart';

import '../models/mrkz_test_models.dart';

class MrkzTestsApi {
  MrkzTestsApi(this._client);

  final TeacherApiClient _client;

  Future<List<MrkzTestDefinitionOption>> getDefinitions(int studentId) {
    return _client.get<List<MrkzTestDefinitionOption>>(
      '/api/students/$studentId/mrkz-tests/definitions',
      parseData: (json) {
        final list = json as List<dynamic>? ?? [];
        return list
            .whereType<Map>()
            .map((e) => MrkzTestDefinitionOption.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
  }

  Future<MrkzTestsPage> getTests(int studentId) {
    return _client.get<MrkzTestsPage>(
      '/api/students/$studentId/mrkz-tests',
      parseData: (json) => MrkzTestsPage.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<String> createTest(int studentId, SaveMrkzTestResultRequest request) {
    return _client.postCommand(
      '/api/students/$studentId/mrkz-tests',
      body: request.toJson(),
    );
  }

  Future<DownloadedBytes> getCertificatePdf(int resultId) {
    return _client.getBytes(
      '/api/mrkz-test-certificates/$resultId/pdf',
      fallbackFileName:
          'mrkz_certificate_${resultId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Uri certificatePdfUri({
    required int resultId,
    String? accessToken,
  }) {
    final path = UnifiedApiConfig.teacherPath(
      '/api/mrkz-test-certificates/$resultId/pdf',
    );
    return Uri.parse('${UnifiedApiConfig.teacherBaseUrl}$path').replace(
      queryParameters: {
        if (accessToken != null && accessToken.isNotEmpty)
          'access_token': accessToken,
      },
    );
  }
}
