import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../dashboard/providers/teacher_attendance_providers.dart';
import '../data/attendance_api.dart';
import '../data/attendance_repository.dart';

final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  return AttendanceApi(ref.watch(apiClientProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(
    ref.watch(homeApiProvider),
    ref.watch(attendanceApiProvider),
    ref.watch(locationServiceProvider),
  );
});

final attendanceStudentsProvider =
    FutureProvider.autoDispose<List<StudentListItem>>((ref) {
  return ref.watch(attendanceRepositoryProvider).loadStudents();
});

final attendanceControllerProvider = Provider<AttendanceController>((ref) {
  return AttendanceController(ref);
});

class AttendanceController {
  AttendanceController(this._ref);

  final Ref _ref;

  AttendanceRepository get _repository =>
      _ref.read(attendanceRepositoryProvider);

  Future<String> saveChanges({
    required bool isAttendanceMode,
    required List<StudentListItem> students,
    required Map<int, String> manualStatus,
    required Map<int, String> initialAttendanceStatus,
    required Map<int, String> initialDepartureStatus,
  }) {
    if (isAttendanceMode) {
      return _repository.saveAttendanceChanges(
        students: students,
        manualStatus: manualStatus,
        initialAttendanceStatus: initialAttendanceStatus,
      );
    }

    return _repository.saveDepartureChanges(
      students: students,
      manualStatus: manualStatus,
      initialDepartureStatus: initialDepartureStatus,
    );
  }

  Future<String> scanMark({
    required bool isAttendanceMode,
    required int studentId,
  }) {
    if (isAttendanceMode) {
      return _repository.scanMarkAttendance(studentId);
    }
    return _repository.scanMarkDeparture(studentId);
  }

  Future<ScanQrResult> scanQr({
    required bool isAttendanceMode,
    required String qrToken,
  }) {
    return _repository.scanQr(
      qrToken: qrToken,
      isDeparture: !isAttendanceMode,
    );
  }

  void refreshAfterChange() {
    _ref.invalidate(attendanceStudentsProvider);
    _ref.invalidate(dashboardPageProvider);
  }
}
