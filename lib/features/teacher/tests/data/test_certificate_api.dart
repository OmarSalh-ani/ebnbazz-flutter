import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import '../models/test_certificate_models.dart';

class TestCertificateApi {
  TestCertificateApi(this._client);

  final TeacherApiClient _client;

  Future<TestCertificate> getCertificate(
    int testId, {
    String testPeriod = 'الفصل الأول',
  }) {
    return _client.get<TestCertificate>(
      '/api/test-certificates/$testId',
      queryParameters: {'testPeriod': testPeriod},
      parseData: (json) =>
          TestCertificate.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<DownloadedBytes> getCertificatePdf(
    int testId, {
    String testPeriod = 'الفصل الأول',
  }) {
    return _client.getBytes(
      '/api/test-certificates/$testId/pdf',
      queryParameters: {'testPeriod': testPeriod},
      fallbackFileName:
          'certificate_${testId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
