import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_theme_extensions.dart';

class StudentSearchField extends StatelessWidget {
  const StudentSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final primary = context.appPrimary;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'بحث باسم الطالب',
        hintStyle: AppFonts.cairo(color: AppColors.textHint),
        prefixIcon: Icon(Icons.search, color: primary),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary),
        ),
      ),
    );
  }
}
