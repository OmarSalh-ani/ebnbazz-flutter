import 'package:masged_parent_app/teacher_core/network/api_client.dart';

import '../models/mrkz_memorizing_item.dart';

class MrkzMemorizingRevisionApi {
  MrkzMemorizingRevisionApi(this._client);

  final TeacherApiClient _client;

  Future<List<MrkzMemorizingItem>> getMemorizing(int studentId) {
    return _client.get<List<MrkzMemorizingItem>>(
      '/api/MrkzMemorizingRevision/memorizing/$studentId',
      parseData: (json) => _parseList(json, MrkzMemorizingItem.fromMemorizingJson),
    );
  }

  Future<List<MrkzMemorizingItem>> getRevision(int studentId) {
    return _client.get<List<MrkzMemorizingItem>>(
      '/api/MrkzMemorizingRevision/revision/$studentId',
      parseData: (json) => _parseList(json, MrkzMemorizingItem.fromRevisionJson),
    );
  }

  Future<List<MrkzMemorizingItem>> getMergedArchive(int studentId) async {
    final results = await Future.wait([
      getMemorizing(studentId),
      getRevision(studentId),
    ]);
    final merged = [...results[0], ...results[1]];
    merged.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return merged;
  }

  Future<String> createMemorizing({
    required int studentId,
    required String mtnName,
    required String fromMtn,
    required String toMtn,
  }) async {
    await _client.postVoid(
      '/api/MrkzMemorizingRevision/memorizing/$studentId',
      body: {
        'mtnName': mtnName,
        'fromMtn': fromMtn,
        'toMtn': toMtn,
      },
    );
    return 'تم حفظ السجل بنجاح';
  }

  Future<String> createRevision({
    required int studentId,
    required String mtnName,
    required String fromMtn,
    required String toMtn,
  }) async {
    await _client.postVoid(
      '/api/MrkzMemorizingRevision/revision/$studentId',
      body: {
        'mtnName': mtnName,
        'fromMtn': fromMtn,
        'toMtn': toMtn,
      },
    );
    return 'تم حفظ السجل بنجاح';
  }

  Future<String> updateMemorizing({
    required int studentId,
    required int recordId,
    required String mtnName,
    required String fromMtn,
    required String toMtn,
  }) {
    return _client.putCommand(
      '/api/MrkzMemorizingRevision/memorizing/$studentId/$recordId',
      body: {
        'mtnName': mtnName,
        'fromMtn': fromMtn,
        'toMtn': toMtn,
      },
    );
  }

  Future<String> updateRevision({
    required int studentId,
    required int recordId,
    required String mtnName,
    required String fromMtn,
    required String toMtn,
  }) {
    return _client.putCommand(
      '/api/MrkzMemorizingRevision/revision/$studentId/$recordId',
      body: {
        'mtnName': mtnName,
        'fromMtn': fromMtn,
        'toMtn': toMtn,
      },
    );
  }

  Future<String> deleteMemorizing({
    required int studentId,
    required int recordId,
  }) {
    return _client.deleteCommand(
      '/api/MrkzMemorizingRevision/memorizing/$studentId/$recordId',
    );
  }

  Future<String> deleteRevision({
    required int studentId,
    required int recordId,
  }) {
    return _client.deleteCommand(
      '/api/MrkzMemorizingRevision/revision/$studentId/$recordId',
    );
  }

  List<MrkzMemorizingItem> _parseList(
    dynamic json,
    MrkzMemorizingItem Function(Map<String, dynamic>) mapper,
  ) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) => mapper(Map<String, dynamic>.from(e)))
        .toList();
  }
}
