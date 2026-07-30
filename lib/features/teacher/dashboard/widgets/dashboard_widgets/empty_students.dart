import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';

class EmptyStudents extends StatelessWidget {
  const EmptyStudents({
    super.key,
    this.isSearchResult = false,
  });

  final bool isSearchResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isSearchResult ? 'لا توجد نتائج للبحث' : 'لا يوجد طلاب في الحلقة',
        textAlign: TextAlign.center,
        style: AppFonts.cairo(color: AppColors.textSecondary),
      ),
    );
  }
}
