import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../public_home_constants.dart';

class PublicSectionHeader extends StatelessWidget {
  const PublicSectionHeader({
    super.key,
    required this.meta,
    this.onViewAll,
  });

  final PublicSectionMeta meta;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(PublicHomeConstants.accentGold)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(PublicHomeConstants.accentGold)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    meta.badge,
                    style: AppFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B6914),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  meta.title,
                  style: AppFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meta.subtitle,
                  style: AppFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (onViewAll != null && meta.viewAllLabel != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: Text(meta.viewAllLabel!),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppFonts.cairo(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
