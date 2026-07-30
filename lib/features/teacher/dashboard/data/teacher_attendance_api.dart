import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import '../models/teacher_attendance_models.dart';

class TeacherAttendanceApi {
  TeacherAttendanceApi(this._client);

  final TeacherApiClient _client;

  Future<TeacherAttendanceStatus> getStatus() {
    return _client.get<TeacherAttendanceStatus>(
      '/api/TeacherAttendance/status',
      parseData: (json) =>
          TeacherAttendanceStatus.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<String> markAttendance(LocationRequest request) {
    return _client.postCommand(
      '/api/TeacherAttendance/mark-attendance',
      body: request.toJson(),
    );
  }

  Future<String> markDeparture(LocationRequest request) {
    return _client.postCommand(
      '/api/TeacherAttendance/mark-departure',
      body: request.toJson(),
    );
  }

  Future<void> registerFingerprint(String fingerprintHash) async {
    await _client.postCommand(
      '/api/TeacherAttendance/register-fingerprint',
      body: {'fingerprintHash': fingerprintHash},
    );
  }

  Future<void> reRegisterFingerprint({
    required String fingerprintHash,
    required String password,
  }) async {
    await _client.postCommand(
      '/api/TeacherAttendance/re-register-fingerprint',
      body: {
        'fingerprintHash': fingerprintHash,
        'password': password,
      },
    );
  }

  Future<MosqueProximity> getProximity({
    required double latitude,
    required double longitude,
  }) {
    return _client.get<MosqueProximity>(
      '/api/TeacherAttendance/proximity',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
      },
      parseData: (json) =>
          MosqueProximity.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<TeacherAttendanceLogResponse> getAttendanceLog({
    required String fromDate,
    required String toDate,
  }) {
    return _client.get<TeacherAttendanceLogResponse>(
      '/api/TeacherAttendance/log',
      queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
      },
      parseData: (json) =>
          TeacherAttendanceLogResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
