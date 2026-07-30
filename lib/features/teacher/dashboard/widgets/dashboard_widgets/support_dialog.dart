import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

Future<void> showSupportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'الدعم الفني',
        style: AppFonts.cairo(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'للمساعدة تقنيًا، تواصل مع إدارة المسجد أو فريق تقنية المعلومات المعتمد لديكم.',
        style: AppFonts.cairo(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'حسناً',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
