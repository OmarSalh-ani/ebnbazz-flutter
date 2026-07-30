import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import '../../../auth/providers/auth_providers.dart';

Future<void> showLogoutConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'تسجيل الخروج',
        textAlign: TextAlign.right,
        style: AppFonts.cairo(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟',
        textAlign: TextAlign.right,
        style: AppFonts.cairo(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'إلغاء',
            style: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
          child: Text(
            'تسجيل الخروج',
            style: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    ),
  );
}
