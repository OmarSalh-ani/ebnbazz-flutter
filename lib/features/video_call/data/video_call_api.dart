import '../../../teacher_core/network/api_client.dart';
import '../models/video_call_models.dart';

class VideoCallApi {
  VideoCallApi(this._client);

  final TeacherApiClient _client;

  Future<VideoCallCatalog> fetchCatalog() {
    return _client.get<VideoCallCatalog>(
      '/api/VideoCall/students',
      parseData: (json) =>
          VideoCallCatalog.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<List<VideoCallListRow>> listMeetings() {
    return _client.get<List<VideoCallListRow>>(
      '/api/VideoCall',
      parseData: (json) {
        final list = json as List<dynamic>;
        return list
            .map(
              (e) => VideoCallListRow.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      },
    );
  }

  Future<VideoCallCreatedResult> createCall({
    required String meetingName,
    required List<int> studentIds,
    bool sendWhatsApp = true,
    String? teacherName,
  }) {
    return _client.post<VideoCallCreatedResult>(
      '/api/VideoCall',
      body: {
        'meetingName': meetingName,
        'studentIds': studentIds,
        'sendWhatsApp': sendWhatsApp,
        if (teacherName != null && teacherName.trim().isNotEmpty)
          'teacherName': teacherName.trim(),
      },
      parseData: (json) => VideoCallCreatedResult.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<VideoCallTokenResult> refreshToken(int meetingId) {
    return _client.post<VideoCallTokenResult>(
      '/api/VideoCall/$meetingId/token',
      body: <String, dynamic>{},
      parseData: (json) => VideoCallTokenResult.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<String> deleteMeeting(int id) => _client.deleteCommand('/api/VideoCall/$id');

  Future<String> addStudentsToMeeting({
    required int meetingId,
    required List<int> studentIds,
    bool sendWhatsApp = true,
  }) {
    return _client.postCommand(
      '/api/VideoCall/$meetingId/students',
      body: {
        'studentIds': studentIds,
        'sendWhatsApp': sendWhatsApp,
      },
    );
  }
}
