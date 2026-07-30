import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/app/models/app_role.dart';
import 'package:masged_parent_app/app/providers/app_role_provider.dart';
import 'package:masged_parent_app/features/auth/providers/auth_provider.dart';
import 'package:masged_parent_app/features/chat/models/chat_teacher_thread.dart';
import 'package:masged_parent_app/features/teacher/auth/providers/auth_providers.dart';
import 'package:masged_parent_app/features/teacher/chat/models/parent_chat_thread_vm.dart';
import 'package:masged_parent_app/features/teacher/chat/screens/teacher_chat_detail_screen.dart';
import 'package:masged_parent_app/features/teacher/chat/utils/open_student_parent_chat.dart';
import 'package:masged_parent_app/shared/router/app_router.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';

class ChatPushTarget {
  const ChatPushTarget({
    required this.teacherId,
    required this.studentId,
    this.teacherName,
    this.studentName,
    this.parentPhone,
  });

  final int teacherId;
  final int studentId;
  final String? teacherName;
  final String? studentName;
  final String? parentPhone;
}

Future<void> openChatFromPushNotification(
  WidgetRef ref,
  ChatPushTarget target,
) async {
  final role = ref.read(appRoleProvider);

  if (role == AppRole.teacher) {
    await _openTeacherChat(ref, target);
    return;
  }

  await _openParentChat(ref, target);
}

Future<void> _openParentChat(WidgetRef ref, ChatPushTarget target) async {
  final auth = ref.read(authProvider);
  if (!auth.isAuthenticated) {
    _showMessage(ref, 'يرجى تسجيل الدخول.');
    return;
  }

  final userPhone = auth.user?.phone ?? '';
  final canonical = normalizeCanonicalParentPhone(userPhone);

  final thread = ChatTeacherThread(
    teacherId: target.teacherId,
    studentId: target.studentId,
    teacherName: target.teacherName?.trim().isNotEmpty == true
        ? target.teacherName!.trim()
        : 'المعلم',
    studentName: target.studentName?.trim().isNotEmpty == true
        ? target.studentName!.trim()
        : 'الطالب',
    subtitle: '',
    canonicalParentPhone: canonical,
  );

  final router = ref.read(appRouterProvider);
  final context = router.routerDelegate.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;

  context.push(
    AppRoutes.chatDetailPath('${target.teacherId}', '${target.studentId}'),
    extra: thread,
  );
}

Future<void> _openTeacherChat(WidgetRef ref, ChatPushTarget target) async {
  final auth = await ref.read(authControllerProvider.future);
  if (auth == null || !auth.isSessionValid) {
    _showMessage(ref, 'يرجى تسجيل الدخول.');
    return;
  }

  if (auth.id != target.teacherId) {
    _showMessage(ref, 'هذه المحادثة لا تخص حسابك.');
    return;
  }

  final parentPhone = target.parentPhone?.trim().isNotEmpty == true
      ? normalizeCanonicalParentPhone(target.parentPhone!)
      : '';

  final thread = ParentChatThreadVm(
    canonicalParentPhone: parentPhone,
    teacherId: target.teacherId,
    studentId: target.studentId,
    studentName: target.studentName,
    parentDisplayName: target.studentName != null
        ? 'ولي أمر ${target.studentName}'
        : 'ولي الأمر',
  );

  final context =
      ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;

  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => TeacherChatDetailScreen(thread: thread),
    ),
  );
}

void _showMessage(WidgetRef ref, String text) {
  final context =
      ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text, style: AppFonts.cairo())),
  );
}
