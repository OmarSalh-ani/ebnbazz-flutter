import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

Future<void> showParentChangePasswordDialog(
  BuildContext context,
  WidgetRef ref,
) {
  final passwordController = TextEditingController();
  var isLoading = false;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
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
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
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
                    final password = passwordController.text.trim();
                    if (password.length < 6) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
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
                      await ref.read(authProvider.notifier).changePassword(password);
                      if (!context.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم تغيير كلمة المرور بنجاح',
                            style: AppFonts.cairo(),
                          ),
                        ),
                      );
                    } on ApiException catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.message, style: AppFonts.cairo()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'فشل تغيير كلمة المرور',
                            style: AppFonts.cairo(),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } finally {
                      if (dialogContext.mounted) {
                        setDialogState(() => isLoading = false);
                      }
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
  ).whenComplete(passwordController.dispose);
}
