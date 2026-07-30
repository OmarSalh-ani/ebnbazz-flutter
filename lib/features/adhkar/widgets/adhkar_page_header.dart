import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

class AdhkarPageHeader extends StatelessWidget {
  const AdhkarPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Icon(
            Icons.mosque_rounded,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco_rounded,
                color: AppColors.primary.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'الأذكار والأدعية',
                style: AppFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.eco_rounded,
                color: AppColors.primary.withValues(alpha: 0.6),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'أحصن نفسك بذكر الله في كل وقت',
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
