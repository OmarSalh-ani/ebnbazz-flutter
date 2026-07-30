import 'package:flutter/material.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/widgets/mosque_section_header.dart';
import '../../models/dashboard_models.dart';
import 'attendance_overview_bar.dart';
import 'stat_card.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.stats,
  });

  final StudentsStatistics stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalStudents;
    final presentPct =
        total > 0 ? ((stats.presentStudents / total) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MosqueSectionHeader('إحصائيات اليوم'),
        const SizedBox(height: 12),
        if (total > 0) ...[
          AttendanceOverviewBar(stats: stats, presentPct: presentPct),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                tooltip: 'إجمالي الطلاب',
                value: '${stats.totalStudents}',
                icon: Icons.groups_rounded,
                color: AppColors.primary,
                lightColor: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardStatCard(
                tooltip: 'الحاضرون',
                value: '${stats.presentStudents}',
                icon: Icons.how_to_reg_rounded,
                color: AppColors.success,
                lightColor: AppColors.successLight,
                badge: total > 0 ? '$presentPct%' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardStatCard(
                tooltip: 'الغائبون',
                value: '${stats.absentStudents}',
                icon: Icons.person_off_rounded,
                color: AppColors.error,
                lightColor: AppColors.errorLight,
                badge: total > 0
                    ? '${((stats.absentStudents / total) * 100).round()}%'
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardStatCard(
                tooltip: 'المنصرفون',
                value: '${stats.departedStudents}',
                icon: Icons.logout_rounded,
                color: AppColors.warning,
                lightColor: AppColors.warningLight,
                badge: total > 0
                    ? '${((stats.departedStudents / total) * 100).round()}%'
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
