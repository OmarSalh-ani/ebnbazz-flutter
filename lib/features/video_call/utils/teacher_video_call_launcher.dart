import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../teacher/attendance/providers/attendance_providers.dart';
import '../../teacher/auth/providers/auth_providers.dart';
import '../models/video_call_models.dart';
import '../models/video_call_session.dart';
import '../providers/video_call_providers.dart';
import '../screens/agora_video_call_screen.dart';
import 'video_call_participant_utils.dart';

Future<void> rejoinTeacherMeeting(
  WidgetRef ref,
  BuildContext context,
  VideoCallListRow row,
) async {
  if (row.isEnded) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'انتهت هذه المكالمة ولا يمكن الانضمام إليها.',
          style: AppFonts.cairo(),
        ),
      ),
    );
    return;
  }

  final authUser = await ref.read(authControllerProvider.future);
  final jwt = authUser?.token.trim();
  if (!context.mounted) return;
  if (jwt == null || jwt.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('انتهت الجلسة.', style: AppFonts.cairo())),
    );
    return;
  }

  try {
    final tok = await ref.read(videoCallApiProvider).refreshToken(row.id);
    final students = ref.read(attendanceStudentsProvider).value ?? const [];
    final participants = participantsFromMeetingRow(row, students);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgoraVideoCallScreen(
          hubJwt: jwt,
          session: VideoCallSession.teacher(
            channelName: tok.channelName,
            token: tok.token,
            uid: tok.uid,
            meetingId: row.id,
            displayTitle: row.meetingName,
            startDateTime: row.startDateTime,
            participantsByStudentId: participants,
          ),
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
