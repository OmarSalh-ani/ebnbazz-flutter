import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';

/// Background and foreground colors for plan row status badges and list tiles.
class PlanRowStatusColors {
  PlanRowStatusColors._();

  static Color statusColor(String status) {
    if (status.contains('لم يتم')) return AppColors.error;
    if (status.contains('اعادة')) return AppColors.warning;
    if (status.contains('تم')) return AppColors.success;
    return AppColors.textHint;
  }

  static Color tileColor(String status) {
    if (status.contains('لم يتم')) return AppColors.errorLight;
    if (status.contains('اعادة')) return AppColors.warningLight;
    if (status.contains('تم')) return AppColors.successLight;
    return AppColors.inputFill;
  }
}
