import 'package:masged_parent_app/teacher_core/network/api_client.dart';

import '../../../children/models/student_plan_models.dart';
import '../../../memorizing_archive/models/memorizing_archive_item.dart';

class MemorizingArchiveApi {
  MemorizingArchiveApi(this._client);

  final TeacherApiClient _client;

  Future<PagedResult<MemorizingArchiveItem>> getArchive(
    int studentId, {
    required int page,
    int pageSize = 20,
    String? surahSearch,
  }) {
    final trimmed = surahSearch?.trim();
    return _client.get<PagedResult<MemorizingArchiveItem>>(
      '/api/memorizing-archive/$studentId',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (trimmed != null && trimmed.isNotEmpty) 'surahSearch': trimmed,
      },
      parseData: (json) => PagedResult.fromJson(
        Map<String, dynamic>.from(json as Map),
        MemorizingArchiveItem.fromJson,
      ),
    );
  }
}
