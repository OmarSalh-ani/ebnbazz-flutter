import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../../models/dashboard_models.dart';
import 'legend_dot.dart';

class AttendanceOverviewBar extends StatelessWidget {
  const AttendanceOverviewBar({
    super.key,
    required this.stats,
    required this.presentPct,
  });

  final StudentsStatistics stats;
  final int presentPct;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalStudents;
    final presentFlex = stats.presentStudents.clamp(0, total);
    final absentFlex = stats.absentStudents.clamp(0, total);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص الحضور',
                      style: AppFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$presentPct% من الطلاب حاضرون اليوم',
                      style: AppFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$presentPct%',
                style: AppFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (presentFlex > 0)
                    Expanded(
                      flex: presentFlex,
                      child: Container(color: AppColors.success),
                    ),
                  if (absentFlex > 0)
                    Expanded(
                      flex: absentFlex,
                      child: Container(
                        color: AppColors.error.withValues(alpha: 0.85),
                      ),
                    ),
                  if (presentFlex + absentFlex < total)
                    Expanded(
                      flex: total - presentFlex - absentFlex,
                      child: Container(color: AppColors.border),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              LegendDot(color: AppColors.success, label: 'حاضر'),
              SizedBox(width: 16),
              LegendDot(color: AppColors.error, label: 'غائب'),
            ],
          ),
        ],
      ),
    );
  }
}
