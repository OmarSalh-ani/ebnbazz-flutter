import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Device biometric gate + teacher-bound enrollment secret hashing.
/// Raw biometric data never leaves the OS; only a derived SHA-256 hash is sent to the API.
class TeacherAttendanceFingerprintService {
  TeacherAttendanceFingerprintService(this._prefs);

  final SharedPreferences _prefs;
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const _uuid = Uuid();

  static String _secretKey(int teacherId) =>
      'attendance_fp_secret_$teacherId';

  static String computeHash(int teacherId, String enrollmentSecret) {
    final payload = '$teacherId:$enrollmentSecret';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final biometrics = await _localAuth.getAvailableBiometrics();
      return (canCheck || isSupported) && biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    required bool isFirstEnrollment,
    bool isDeviceTransfer = false,
  }) async {
    if (kIsWeb) {
      throw TeacherAttendanceFingerprintException(
        'التحقق بالبصمة غير متاح على الويب. استخدم تطبيق الجوال.',
      );
    }

    final canUse = await canUseBiometrics();
    if (!canUse) {
      throw TeacherAttendanceFingerprintException(
        'لم يتم إعداد البصمة على هذا الجهاز',
      );
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: isDeviceTransfer
            ? 'أكّد بصمتك لتسجيل الحضور على هذا الجهاز'
            : isFirstEnrollment
                ? 'سجّل بصمة الحضور للمرة الأولى'
                : 'أدخل بصمة الإصبع لتسجيل الحضور أو الانصراف',
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled) {
        throw TeacherAttendanceFingerprintCanceled();
      }
      throw TeacherAttendanceFingerprintException(
        _biometricErrorMessage(e.code),
      );
    }
  }

  String? getStoredEnrollmentSecret(int teacherId) {
    return _prefs.getString(_secretKey(teacherId));
  }

  Future<void> saveEnrollmentSecret(int teacherId, String secret) async {
    await _prefs.setString(_secretKey(teacherId), secret);
  }

  Future<void> clearEnrollmentSecret(int teacherId) async {
    await _prefs.remove(_secretKey(teacherId));
  }

  /// Generates a fresh enrollment secret + hash without persisting locally yet.
  ({String secret, String hash}) createEnrollmentCredentials(int teacherId) {
    final secret = _uuid.v4();
    return (
      secret: secret,
      hash: computeHash(teacherId, secret),
    );
  }

  /// After successful [authenticate], returns the hash to register or verify on the API.
  Future<String> resolveFingerprintHash({
    required int teacherId,
    required bool serverHasFingerprint,
  }) async {
    var secret = getStoredEnrollmentSecret(teacherId);
    final needsEnrollment = !serverHasFingerprint || secret == null || secret.isEmpty;

    if (needsEnrollment) {
      secret = _uuid.v4();
      await saveEnrollmentSecret(teacherId, secret);
    }

    return computeHash(teacherId, secret);
  }

  String biometricErrorMessage(LocalAuthExceptionCode code) =>
      _biometricErrorMessage(code);

  String _biometricErrorMessage(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return 'لم يتم إعداد البصمة أو Face ID على هذا الجهاز.';
      case LocalAuthExceptionCode.biometricLockout:
      case LocalAuthExceptionCode.temporaryLockout:
        return 'تم قفل البصمة مؤقتاً. حاول لاحقاً.';
      case LocalAuthExceptionCode.uiUnavailable:
        return 'تعذّر فتح نافذة التحقق بالبصمة. أعد تشغيل التطبيق وحاول مرة أخرى.';
      case LocalAuthExceptionCode.authInProgress:
        return 'يوجد تحقق بالبصمة قيد التنفيذ. انتظر قليلاً ثم حاول مرة أخرى.';
      default:
        return 'تعذّر التحقق بالبصمة. حاول مرة أخرى.';
    }
  }
}

class TeacherAttendanceFingerprintException implements Exception {
  TeacherAttendanceFingerprintException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TeacherAttendanceFingerprintCanceled implements Exception {
  @override
  String toString() => 'canceled';
}

/// Server has a fingerprint but this device lost its enrollment secret (new phone, reinstall, etc.).
class TeacherAttendanceDeviceReEnrollmentRequired implements Exception {
  @override
  String toString() => 'device_re_enrollment_required';
}
