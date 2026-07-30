import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../auth/widgets/session_expired_dialog.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../models/parent_chat_thread_vm.dart';
import '../screens/teacher_chat_detail_screen.dart';

/// Matches backend [PhoneNormalizer.ToCanonical] (8-digit Kuwait local key).
String normalizeCanonicalParentPhone(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('965') && digits.length > 8) {
    digits = digits.substring(3);
  }
  if (digits.length > 8) {
    digits = digits.substring(digits.length - 8);
  }
  return digits;
}

Future<void> openStudentParentChat(
  BuildContext context,
  WidgetRef ref,
  StudentListItem student,
) async {
  final rawPhone = student.fatherPhone.trim();
  if (rawPhone.isEmpty) {
    _showSnack(context, 'لا يوجد رقم ولي أمر مسجل لهذا الطالب');
    return;
  }

  final canonical = normalizeCanonicalParentPhone(rawPhone);
  if (canonical.length != 8) {
    _showSnack(context, 'رقم ولي الأمر غير صالح');
    return;
  }

  final auth = await ref.read(authControllerProvider.future);
  if (!context.mounted) return;

  if (auth == null || !auth.isSessionValid) {
    await showTeacherSessionExpiredDialog(context, ref);
    return;
  }

  final thread = ParentChatThreadVm(
    canonicalParentPhone: canonical,
    teacherId: auth.id,
    studentId: student.id,
    studentName: student.name,
    parentDisplayName: 'ولي أمر ${student.name}',
  );

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TeacherChatDetailScreen(thread: thread),
    ),
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: AppFonts.cairo()),
    ),
  );
}
