import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';

class LegendDot extends StatelessWidget {
  const LegendDot({
    super.key,
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppFonts.cairo(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
