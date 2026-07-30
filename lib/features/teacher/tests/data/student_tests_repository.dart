import '../models/student_test_models.dart';
import 'student_tests_api.dart';

class StudentTestsRepository {
  StudentTestsRepository(this._api);

  final StudentTestsApi _api;

  Future<StudentTestsPage> getTestsPage(int studentId) =>
      _api.getTests(studentId);

  Future<List<StudentTestDetail>> loadTestsWithDetails(int studentId) async {
    final page = await _api.getTests(studentId);
    if (page.tests.isEmpty) return [];

    final details = await Future.wait(
      page.tests.map((test) => _api.getTest(studentId, test.testId)),
    );
    return details;
  }

  Future<String> createTest(int studentId, SaveStudentTestRequest request) =>
      _api.createTest(studentId, request);
}
