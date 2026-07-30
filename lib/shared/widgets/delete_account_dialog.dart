import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../core/theme/app_colors.dart';

Future<bool> showDeleteAccountDialog(
  BuildContext context, {
  required Future<void> Function(String password) onConfirm,
}) async {
  final passwordController = TextEditingController();
  var isLoading = false;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: !isLoading,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'حذف الحساب',
          textAlign: TextAlign.right,
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سيتم حذف حسابك وبياناتك الشخصية نهائياً. '
              'سجلات الطلاب التعليمية ستبقى لدى المسجد دون بياناتك الشخصية.',
              textAlign: TextAlign.right,
              style: AppFonts.cairo(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              enabled: !isLoading,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'أدخل كلمة المرور للتأكيد',
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
            onPressed: isLoading ? null : () => Navigator.pop(context, false),
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
                    if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'يرجى إدخال كلمة المرور',
                            style: AppFonts.cairo(),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);
                    try {
                      await onConfirm(password);
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString(),
                              style: AppFonts.cairo(),
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    } finally {
                      if (context.mounted) {
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
                    'حذف الحساب',
                    style: AppFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );

  passwordController.dispose();
  return confirmed ?? false;
}
