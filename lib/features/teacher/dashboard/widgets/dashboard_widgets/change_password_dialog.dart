import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../../../auth/providers/auth_providers.dart';

Future<void> showChangePasswordDialog(
  BuildContext context,
  WidgetRef ref,
) {
  final passwordController = TextEditingController();
  bool isLoading = false;

  return showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'تغيير كلمة المرور',
          textAlign: TextAlign.right,
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'كلمة المرور الجديدة',
                hintStyle: AppFonts.cairo(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),
          ],
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
            onPressed: isLoading
                ? null
                : () async {
                    if (passwordController.text.trim().length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
                            style: AppFonts.cairo(),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);
                    try {
                      await ref
                          .read(authControllerProvider.notifier)
                          .changePassword(passwordController.text.trim());
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم تغيير كلمة المرور بنجاح',
                              style: AppFonts.cairo(),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'فشل تغيير كلمة المرور',
                              style: AppFonts.cairo(),
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    } finally {
                      setDialogState(() => isLoading = false);
                    }
                  },
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'حفظ',
                    style: AppFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
