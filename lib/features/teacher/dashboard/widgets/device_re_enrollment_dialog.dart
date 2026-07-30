import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';

Future<String?> showDeviceReEnrollmentDialog(BuildContext context) {
  final passwordController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'تسجيل الجهاز الجديد',
          textAlign: TextAlign.right,
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تم تسجيل بصمة الحضور على جهاز آخر. أدخل كلمة المرور لتفعيل هذا الجهاز.',
              textAlign: TextAlign.right,
              style: AppFonts.cairo(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'كلمة المرور',
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
            onPressed: () {
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
              Navigator.pop(context, password);
            },
            child: Text(
              'تأكيد',
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
