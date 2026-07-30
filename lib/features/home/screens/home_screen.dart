import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_review_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../children/models/child_model.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import '../../adhkar/widgets/adhkar_reminder_card.dart';
import '../../video_call/widgets/ongoing_meeting_card.dart';
import '../providers/news_read_provider.dart';
import '../../children/providers/students_provider.dart';

import '../../../shared/widgets/student_avatar.dart';
import '../../../shared/widgets/mosque_section_header.dart';
import '../../../shared/widgets/quick_services.dart';
import '../../../shared/utils/connectivity_guard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapAppReview());
    });
  }

  Future<void> _bootstrapAppReview() async {
    await AppReviewService.recordLaunch();
    await AppReviewService.maybePrompt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
            title: Text(
              'الرئيسية',
              style: AppFonts.cairo(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                onPressed: () => ConnectivityGuard.tryNavigate(
                  ref,
                  () => context.push(AppRoutes.chatTeachers),
                  context: context,
                  route: AppRoutes.chatTeachers,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => ConnectivityGuard.tryNavigate(
                  ref,
                  () => context.push(AppRoutes.notifications),
                  context: context,
                  route: AppRoutes.notifications,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                const AdhkarReminderCard(),
                const ParentOngoingMeetingCard(),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MosqueSectionHeader('خدمات سريعة'),
                      const SizedBox(height: 12),
                      QuickServicesRowNeutral(
                        items:
                            QuickServiceItem.islamicShortcuts(
                              unreadNewsBadge:
                                  ref.watch(hasUnreadNewsProvider),
                            ),
                        trailingTile: GestureDetector(
                          onTap: () => context.go(AppRoutes.services),
                          child: SizedBox(
                            width: 85,
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.grid_view_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'الكل',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // My Children Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'أبنائي',
                              style: AppFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(AppRoutes.children),
                              child: Text(
                                'عرض الكل',
                                style: AppFonts.cairo(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildChildrenList(context, ref),
                    ],
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        );
  }



  Widget _buildChildCard(BuildContext context, ChildModel child) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (child.status) {
      case ChildStatus.inMasged:
        statusColor = const Color(0xFF10B981); // Emerald
        statusText = 'في المسجد';
        statusIcon = Icons.check_circle_outline;
        break;
      case ChildStatus.left:
        statusColor = const Color(0xFFF59E0B); // Amber
        statusText = 'غادر المسجد';
        statusIcon = Icons.exit_to_app_rounded;
        break;
      case ChildStatus.vacation:
        statusColor = const Color(0xFF64748B);
        statusText = 'إجازة اليوم';
        statusIcon = Icons.beach_access_outlined;
        break;
      case ChildStatus.absent:
        statusColor = const Color(0xFFEF4444); // Red
        statusText = 'غائب اليوم';
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.childProfile, extra: child),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar with Glow/Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              statusColor.withOpacity(0.2),
                              statusColor.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: StudentAvatar(
                          imageUrl: child.avatarUrl,
                          size: 60,
                        ),
                      ),
                      // Small status dot
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Main Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      color: statusColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: AppFonts.cairo(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school_outlined,
                                    size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  child.level,
                                  style: AppFonts.cairo(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.push(AppRoutes.quran, extra: child),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.menu_book_rounded,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'الحفظ القادم',
                                      style: AppFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (child.logTime != null) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              'دخول: ${child.logTime}',
                              style: AppFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (child.status == ChildStatus.left &&
                            child.departureTime != null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              'خروج: ${child.departureTime}',
                              style: AppFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Weekly Attendance Tracker
            if (child.weeklyAttendance != null)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'متابعة الحضور الأسبوعي',
                      style: AppFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: child.weeklyAttendance!.entries.map((entry) {
                        final day = entry.key;
                        final isPresent = entry.value;

                        Color color;
                        if (isPresent == true) {
                          color = const Color(0xFF10B981); // Emerald
                        } else if (isPresent == false) {
                          color = const Color(0xFFEF4444); // Red
                        } else {
                          color = Colors.grey.withOpacity(0.2); // Future
                        }

                        return Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: isPresent != null
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                {
                                      'السبت': 'س',
                                      'الأحد': 'ح',
                                      'الاثنين': 'ن',
                                      'الثلاثاء': 'ث',
                                      'الأربعاء': 'ر',
                                      'الخميس': 'خ',
                                      'الجمعة': 'ج',
                                    }[day] ??
                                    day[0],
                                style: AppFonts.cairo(
                                  color: isPresent != null
                                      ? Colors.white
                                      : AppColors.textHint,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day,
                              style: AppFonts.cairo(
                                fontSize: 10,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            // Notes / Teacher Alert Section
            if (child.notes != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Light Slate
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.05)),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملاحظات المعلم:',
                            style: AppFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            child.notes!,
                            style: AppFonts.cairo(
                              fontSize: 13,
                              color: AppColors.textPrimary.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return studentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Text(
        'تعذر تحميل بيانات الأبناء',
        style: AppFonts.cairo(color: AppColors.textSecondary),
      ),
      data: (children) {
        if (children.isEmpty) {
          return Text(
            'لا يوجد أبناء مسجلون',
            style: AppFonts.cairo(color: AppColors.textSecondary),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _buildChildCard(context, children[i]),
            ],
          ],
        );
      },
    );
  }

}
