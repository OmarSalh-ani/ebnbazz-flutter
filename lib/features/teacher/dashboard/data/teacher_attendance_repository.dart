import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:masged_parent_app/teacher_core/services/location_service.dart';
import 'package:masged_parent_app/teacher_core/services/teacher_attendance_fingerprint_service.dart';
import 'package:masged_parent_app/teacher_core/storage/auth_storage.dart';
import '../models/teacher_attendance_models.dart';
import 'teacher_attendance_api.dart';

class TeacherAttendanceRepository {
  TeacherAttendanceRepository(
    this._api,
    this._locationService,
    this._fingerprintService,
    this._authStorage,
  );

  final TeacherAttendanceApi _api;
  final LocationService _locationService;
  final TeacherAttendanceFingerprintService _fingerprintService;
  final AuthStorage _authStorage;

  Future<TeacherAttendanceStatus> getStatus() => _api.getStatus();

  Future<String> markAttendance({String? reEnrollmentPassword}) =>
      _markWithFingerprint(
        _api.markAttendance,
        reEnrollmentPassword: reEnrollmentPassword,
      );

  Future<String> markDeparture({String? reEnrollmentPassword}) =>
      _markWithFingerprint(
        _api.markDeparture,
        reEnrollmentPassword: reEnrollmentPassword,
      );

  Future<String> _markWithFingerprint(
    Future<String> Function(LocationRequest request) markFn, {
    String? reEnrollmentPassword,
  }) async {
    final user = await _authStorage.getUser();
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final status = await _api.getStatus();
    final localSecret = _fingerprintService.getStoredEnrollmentSecret(user.id);
    final needsDeviceReEnrollment = status.hasFingerprintRegistered &&
        (localSecret == null || localSecret.isEmpty);
    final isFirstEnrollment = !status.hasFingerprintRegistered;

    if (needsDeviceReEnrollment && reEnrollmentPassword == null) {
      final saved = await _authStorage.getSavedCredentials();
      if (saved.password == null || saved.password!.trim().isEmpty) {
        throw TeacherAttendanceDeviceReEnrollmentRequired();
      }
    }

    final canUseBiometrics = await _fingerprintService.canUseBiometrics();
    if (canUseBiometrics) {
      final authenticated = await _fingerprintService.authenticate(
        isFirstEnrollment: isFirstEnrollment || needsDeviceReEnrollment,
        isDeviceTransfer: needsDeviceReEnrollment,
      );
      if (!authenticated) {
        throw TeacherAttendanceFingerprintCanceled();
      }
    }

    late final String fingerprintHash;

    if (needsDeviceReEnrollment) {
      fingerprintHash = await _reRegisterOnThisDevice(
        teacherId: user.id,
        passwordOverride: reEnrollmentPassword,
      );
    } else {
      fingerprintHash = await _fingerprintService.resolveFingerprintHash(
        teacherId: user.id,
        serverHasFingerprint: status.hasFingerprintRegistered,
      );

      if (isFirstEnrollment) {
        await _api.registerFingerprint(fingerprintHash);
      }
    }

    final coords = await _locationService.getCurrentCoordinates();
    return markFn(
      LocationRequest(
        latitude: coords.latitude,
        longitude: coords.longitude,
        fingerprintHash: fingerprintHash,
      ),
    );
  }

  Future<String> _reRegisterOnThisDevice({
    required int teacherId,
    String? passwordOverride,
  }) async {
    await _fingerprintService.clearEnrollmentSecret(teacherId);

    var password = passwordOverride?.trim();
    if (password == null || password.isEmpty) {
      final saved = await _authStorage.getSavedCredentials();
      password = saved.password?.trim();
    }

    if (password == null || password.isEmpty) {
      throw TeacherAttendanceDeviceReEnrollmentRequired();
    }

    final credentials =
        _fingerprintService.createEnrollmentCredentials(teacherId);

    try {
      await _api.reRegisterFingerprint(
        fingerprintHash: credentials.hash,
        password: password,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401 ||
          e.message.contains('كلمة المرور غير صحيحة')) {
        throw TeacherAttendanceDeviceReEnrollmentRequired();
      }
      rethrow;
    }

    await _fingerprintService.saveEnrollmentSecret(
      teacherId,
      credentials.secret,
    );
    return credentials.hash;
  }

  Future<MosqueProximity> getMosqueProximity() async {
    final coords = await _locationService.getCurrentCoordinates();
    return _api.getProximity(
      latitude: coords.latitude,
      longitude: coords.longitude,
    );
  }

  Future<TeacherAttendanceLogResponse> getAttendanceLog({
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    final query = TeacherAttendanceLogQuery(fromDate: fromDate, toDate: toDate);
    return _api.getAttendanceLog(
      fromDate: query.fromDateParam,
      toDate: query.toDateParam,
    );
  }
}
