import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../attendance/providers/attendance_providers.dart';
import '../auth/providers/auth_providers.dart';
import '../chat/providers/teacher_chat_providers.dart';
import '../dashboard/providers/dashboard_providers.dart';
import '../dashboard/providers/teacher_admin_notes_provider.dart';
import '../dashboard/providers/teacher_attendance_providers.dart';
import '../plans/providers/plan_level_providers.dart';
import '../students/providers/students_providers.dart';
import '../../video_call/providers/video_call_providers.dart';

/// Clears cached teacher data so a new login does not show the previous user.
void invalidateTeacherSessionCache(Ref ref) {
  ref.invalidate(dashboardPageProvider);
  ref.invalidate(availableStudentsControllerProvider);
  ref.invalidate(availableStudentsSearchProvider);
  ref.invalidate(attendanceStudentsProvider);
  ref.invalidate(teacherAttendanceStatusProvider);
  ref.invalidate(mosqueProximityProvider);
  ref.invalidate(teacherAdminNotesProvider);
  ref.invalidate(teacherChatThreadsProvider);
  ref.invalidate(planLevelsListProvider);
  ref.invalidate(readyPlansListProvider);
  ref.invalidate(planLevelFormDataProvider);
  ref.invalidate(videoCallMeetingsProvider);
}

/// Watches teacher auth and clears cached data when the signed-in user changes.
final teacherSessionCacheBootstrapProvider = Provider<void>((ref) {
  ref.listen(authControllerProvider, (previous, next) {
    final previousUserId = previous?.valueOrNull?.id;
    final nextUserId = next.valueOrNull?.id;
    if (previousUserId == nextUserId) return;

    invalidateTeacherSessionCache(ref);
  });
});
