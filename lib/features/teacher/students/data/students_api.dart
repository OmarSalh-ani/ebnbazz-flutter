import 'package:masged_parent_app/teacher_core/network/api_client.dart';

import '../../../children/models/student_plan_models.dart';
import '../models/available_student.dart';

class StudentsApi {
  StudentsApi(this._client);

  final TeacherApiClient _client;

  Future<PagedResult<AvailableStudent>> getAvailableStudents({
    String? searchTerm,
    int page = 1,
    int pageSize = 20,
  }) {
    final trimmed = searchTerm?.trim();
    return _client.get<PagedResult<AvailableStudent>>(
      '/api/students/available',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (trimmed != null && trimmed.isNotEmpty) 'searchTerm': trimmed,
      },
      parseData: (json) {
        if (json is List) {
          final items = json
              .whereType<Map>()
              .map(
                (e) => AvailableStudent.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
          return PagedResult(
            items: items,
            page: 1,
            pageSize: items.length,
            totalCount: items.length,
            totalPages: items.isEmpty ? 0 : 1,
          );
        }

        return PagedResult.fromJson(
          Map<String, dynamic>.from(json as Map),
          AvailableStudent.fromJson,
        );
      },
    );
  }

  Future<String> addStudentsToCircle(List<int> studentIds) {
    return _client.postCommand(
      '/api/students/add-to-circle',
      body: {'studentIds': studentIds},
    );
  }

  Future<String> removeStudentFromCircle(int studentId) {
    return _client.postCommand('/api/students/$studentId/remove-from-circle');
  }
}
