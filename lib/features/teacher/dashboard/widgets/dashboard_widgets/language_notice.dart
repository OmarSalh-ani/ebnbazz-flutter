import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

void showLanguageNotice(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'التطبيق يدعم اللغة العربية حاليًا.',
        style: AppFonts.cairo(),
      ),
    ),
  );
}
