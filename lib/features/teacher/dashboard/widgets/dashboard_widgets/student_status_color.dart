import 'package:flutter/material.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';

Color studentStatusColorFor(String status) {
  if (status == 'حاضر') return AppColors.success;
  if (status == 'غائب') return AppColors.error;
  if (status == 'منصرف') return AppColors.warning;
  if (status == 'اجازة') return AppColors.textSecondary;
  return AppColors.textHint;
}
