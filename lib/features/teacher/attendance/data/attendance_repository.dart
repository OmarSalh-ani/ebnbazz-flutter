import 'package:masged_parent_app/teacher_core/services/location_service.dart';

import '../../dashboard/data/home_api.dart';
import '../../dashboard/models/dashboard_models.dart';
import 'attendance_api.dart';

class AttendanceRepository {
  AttendanceRepository(this._homeApi, this._attendanceApi, this._locationService);

  final HomeApi _homeApi;
  final AttendanceApi _attendanceApi;
  final LocationService _locationService;

  Future<List<StudentListItem>> loadStudents() async {
    final home = await _homeApi.getHome();
    return home.students;
  }

  Future<({double latitude, double longitude})> _currentCoordinates() =>
      _locationService.getCurrentCoordinates();

  Future<String> saveAttendanceChanges({
    required List<StudentListItem> students,
    required Map<int, String> manualStatus,
    required Map<int, String> initialAttendanceStatus,
  }) async {
    final coords = await _currentCoordinates();
    final toMarkPresent = <int>[];
    final toMarkAbsent = <int>[];

    for (final student in students) {
      final desired = manualStatus[student.id] ?? 'غائب';
      final initial = initialAttendanceStatus[student.id] ?? 'غائب';

      if (desired == 'حاضر' && initial != 'حاضر' && initial != 'منصرف') {
        toMarkPresent.add(student.id);
      } else if (desired == 'غائب' &&
          (initial == 'حاضر' || initial == 'منصرف')) {
        toMarkAbsent.add(student.id);
      }
    }

    final messages = <String>[];

    if (toMarkPresent.isNotEmpty) {
      messages.add(
        await _attendanceApi.markAttendance(
          toMarkPresent,
          latitude: coords.latitude,
          longitude: coords.longitude,
        ),
      );
    }

    for (final studentId in toMarkAbsent) {
      messages.add(
        await _attendanceApi.undoAttendance(
          studentId,
          latitude: coords.latitude,
          longitude: coords.longitude,
        ),
      );
    }

    if (messages.isEmpty) {
      return 'لا توجد تغييرات للحفظ';
    }

    return messages.last;
  }

  Future<String> saveDepartureChanges({
    required List<StudentListItem> students,
    required Map<int, String> manualStatus,
    required Map<int, String> initialDepartureStatus,
  }) async {
    final coords = await _currentCoordinates();
    final toMarkDeparted = <int>[];
    final toUndoDeparture = <int>[];

    for (final student in students) {
      final desired = manualStatus[student.id] ?? 'لم ينصرف';
      final initial = initialDepartureStatus[student.id] ?? 'لم ينصرف';
      final wantsDeparted = desired == 'منصرف';
      final wasDeparted =
          initial == 'منصرف' || initial.startsWith('انصرف');

      if (wantsDeparted && !wasDeparted) {
        toMarkDeparted.add(student.id);
      } else if (!wantsDeparted && wasDeparted) {
        toUndoDeparture.add(student.id);
      }
    }

    final messages = <String>[];

    if (toMarkDeparted.isNotEmpty) {
      messages.add(
        await _attendanceApi.markDeparture(
          toMarkDeparted,
          latitude: coords.latitude,
          longitude: coords.longitude,
        ),
      );
    }

    for (final studentId in toUndoDeparture) {
      messages.add(
        await _attendanceApi.undoDeparture(
          studentId,
          latitude: coords.latitude,
          longitude: coords.longitude,
        ),
      );
    }

    if (messages.isEmpty) {
      return 'لا توجد تغييرات للحفظ';
    }

    return messages.last;
  }

  Future<String> scanMarkAttendance(int studentId) async {
    final coords = await _currentCoordinates();
    return _attendanceApi.markAttendance(
      [studentId],
      latitude: coords.latitude,
      longitude: coords.longitude,
    );
  }

  Future<String> scanMarkDeparture(int studentId) async {
    final coords = await _currentCoordinates();
    return _attendanceApi.markDeparture(
      [studentId],
      latitude: coords.latitude,
      longitude: coords.longitude,
    );
  }

  Future<ScanQrResult> scanQr({
    required String qrToken,
    required bool isDeparture,
  }) async {
    final coords = await _currentCoordinates();
    return _attendanceApi.scanQr(
      qrToken: qrToken,
      isDeparture: isDeparture,
      latitude: coords.latitude,
      longitude: coords.longitude,
    );
  }

  Future<String> markAllAttendance(List<int> studentIds) async {
    final coords = await _currentCoordinates();
    return _attendanceApi.markAttendance(
      studentIds,
      latitude: coords.latitude,
      longitude: coords.longitude,
    );
  }

  Future<String> markAllDeparture(List<int> studentIds) async {
    final coords = await _currentCoordinates();
    return _attendanceApi.markDeparture(
      studentIds,
      latitude: coords.latitude,
      longitude: coords.longitude,
    );
  }
}
