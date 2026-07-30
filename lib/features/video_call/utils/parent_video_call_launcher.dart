import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/router/app_router.dart';
import '../models/video_call_session.dart';
import '../providers/video_call_providers.dart';
import '../screens/agora_video_call_screen.dart';

/// Joins the active teacher video call for a chat thread, if one exists.
Future<void> openParentVideoCallFromChat(
  WidgetRef ref, {
  required int teacherId,
  required int studentId,
}) async {
  try {
    final meetingId = await ref.read(parentVideoCallApiProvider).findActiveMeeting(
          teacherId: teacherId,
          studentId: studentId,
        );
    if (meetingId == null) {
      _showMessage(
        ref,
        'لا توجد مكالمة فيديو نشطة مع المعلم. اطلب منه بدء مكالمة جديدة.',
      );
      return;
    }
    await openParentVideoCallFromMeeting(
      ref,
      meetingId,
      studentId: studentId,
    );
  } catch (e) {
    _showMessage(ref, e.toString());
  }
}

/// Joins a parent video meeting and opens [AgoraVideoCallScreen].
Future<void> openParentVideoCallFromMeeting(
  WidgetRef ref,
  int meetingId, {
  int? studentId,
  DateTime? startDateTime,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(AppConstants.keyAuthToken)?.trim();
  if (token == null || token.isEmpty) {
    _showMessage(ref, 'يرجى تسجيل الدخول.');
    return;
  }

  try {
    final join = await ref
        .read(parentVideoCallApiProvider)
        .join(meetingId, studentId: studentId);
    final context =
        ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => AgoraVideoCallScreen(
          hubJwt: token,
          session: VideoCallSession.parent(
            channelName: join.channelName,
            token: join.token,
            studentId: join.studentId,
            meetingId: join.meetingId,
            displayTitle: join.meetingName,
            startDateTime: startDateTime,
            teacherRtcUid: join.teacherRtcUid,
          ),
        ),
      ),
    );
  } catch (e) {
    _showMessage(ref, e.toString());
  }
}

void _showMessage(WidgetRef ref, String text) {
  final context =
      ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text, style: AppFonts.cairo())),
  );
}
