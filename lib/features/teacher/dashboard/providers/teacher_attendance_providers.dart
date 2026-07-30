import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/teacher_core/services/location_service.dart';
import 'package:masged_parent_app/teacher_core/services/teacher_attendance_fingerprint_service.dart';
import 'package:masged_parent_app/app/providers/app_role_provider.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/teacher_attendance_api.dart';
import '../data/teacher_attendance_repository.dart';
import '../models/teacher_attendance_models.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final teacherAttendanceFingerprintServiceProvider =
    Provider<TeacherAttendanceFingerprintService>((ref) {
  return TeacherAttendanceFingerprintService(
    ref.watch(sharedPreferencesProvider),
  );
});

final teacherAttendanceApiProvider = Provider<TeacherAttendanceApi>((ref) {
  return TeacherAttendanceApi(ref.watch(apiClientProvider));
});

final teacherAttendanceRepositoryProvider =
    Provider<TeacherAttendanceRepository>((ref) {
  return TeacherAttendanceRepository(
    ref.watch(teacherAttendanceApiProvider),
    ref.watch(locationServiceProvider),
    ref.watch(teacherAttendanceFingerprintServiceProvider),
    ref.watch(authStorageProvider),
  );
});

final teacherAttendanceStatusProvider =
    FutureProvider.autoDispose<TeacherAttendanceStatus>((ref) {
  return ref.watch(teacherAttendanceRepositoryProvider).getStatus();
});

final mosqueProximityProvider =
    FutureProvider.autoDispose<MosqueProximity>((ref) {
  return ref.watch(teacherAttendanceRepositoryProvider).getMosqueProximity();
});

final teacherAttendanceLogProvider = FutureProvider.autoDispose
    .family<TeacherAttendanceLogResponse, TeacherAttendanceLogQuery>((ref, query) {
  return ref.watch(teacherAttendanceRepositoryProvider).getAttendanceLog(
        fromDate: query.fromDate,
        toDate: query.toDate,
      );
});
