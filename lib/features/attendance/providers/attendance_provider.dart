import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_month_query.dart';
import '../models/attendance_record_model.dart';
import '../services/attendance_api_service.dart';

final attendanceApiServiceProvider = Provider((ref) => AttendanceApiService());

final studentAttendanceProvider = FutureProvider.family<
    List<AttendanceRecordModel>,
    AttendanceMonthQuery>((ref, query) {
  return ref.read(attendanceApiServiceProvider).getStudentAttendance(
        query.studentId,
        year: query.year,
        month: query.month,
      );
});
