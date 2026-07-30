import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

void showAboutAppDialog(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'حلقات مسجد مبارك الصباح — المعلم',
    applicationVersion: '1.0.0',
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'لمتابعة الحلقات والطلاب والتواصل مع أولياء الأمور.',
          style: AppFonts.cairo(height: 1.5),
        ),
      ),
    ],
  );
}
