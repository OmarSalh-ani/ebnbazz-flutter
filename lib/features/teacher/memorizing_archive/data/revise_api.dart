import 'package:masged_parent_app/teacher_core/network/api_client.dart';

import '../models/revise_models.dart';

class ReviseApi {
  ReviseApi(this._client);

  final TeacherApiClient _client;

  Future<RevisePageData> getPage(int studentId) {
    return _client.get<RevisePageData>(
      '/api/revise/$studentId',
      parseData: (json) =>
          RevisePageData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<String> create(int studentId, CreateReviseRequest request) {
    return _client.postCommand(
      '/api/revise/$studentId',
      body: request.toJson(),
    );
  }

  Future<List<int>> getAyahNumbers(int surahId) {
    return _client.get<List<int>>(
      '/api/revise/surahs/$surahId/ayahs',
      parseData: (json) {
        final list = json as List<dynamic>;
        return list
            .map((e) => (e as Map<String, dynamic>)['ayahNumber'] as int)
            .toList();
      },
    );
  }
}
