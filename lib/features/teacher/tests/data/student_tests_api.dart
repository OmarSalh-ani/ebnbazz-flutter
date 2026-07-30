import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import '../models/student_test_models.dart';

class StudentTestsApi {
  StudentTestsApi(this._client);

  final TeacherApiClient _client;

  Future<StudentTestsPage> getTests(int studentId) {
    return _client.get<StudentTestsPage>(
      '/api/students/$studentId/tests',
      parseData: (json) =>
          StudentTestsPage.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<StudentTestDetail> getTest(int studentId, int testId) {
    return _client.get<StudentTestDetail>(
      '/api/students/$studentId/tests/$testId',
      parseData: (json) =>
          StudentTestDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<String> createTest(int studentId, SaveStudentTestRequest request) {
    return _client.postCommand(
      '/api/students/$studentId/tests',
      body: request.toJson(),
    );
  }
}
