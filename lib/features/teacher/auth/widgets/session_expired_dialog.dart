import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import '../providers/auth_providers.dart';

Future<void> showTeacherSessionExpiredDialog(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'انتهت الجلسة',
        textAlign: TextAlign.right,
        style: AppFonts.cairo(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        'انتهت صلاحية جلسة تسجيل الدخول. يرجى تسجيل الدخول مرة أخرى.',
        textAlign: TextAlign.right,
        style: AppFonts.cairo(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
          child: Text(
            'موافق',
            style: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
}
