import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/theme/app_colors.dart';
import '../providers/active_meetings_provider.dart';
import '../utils/parent_video_call_launcher.dart';
import '../utils/teacher_video_call_launcher.dart';

class ParentOngoingMeetingCard extends ConsumerWidget {
  const ParentOngoingMeetingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentActiveMeetingsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (meetings) {
        if (meetings.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (var i = 0; i < meetings.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _OngoingMeetingCardShell(
                title: meetings[i].title,
                subtitle: meetings[i].summary,
                startedAt: meetings[i].createdAt,
                onJoin: () => openParentVideoCallFromMeeting(
                  ref,
                  meetings[i].id,
                  startDateTime: meetings[i].createdAt,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class TeacherOngoingMeetingCard extends ConsumerWidget {
  const TeacherOngoingMeetingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherActiveMeetingsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (meetings) {
        if (meetings.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (var i = 0; i < meetings.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _OngoingMeetingCardShell(
                title: meetings[i].meetingName,
                subtitle: meetings[i].studentNames.isNotEmpty
                    ? meetings[i].studentNames
                    : 'مكالمة فيديو نشطة',
                startedAt: meetings[i].startDateTime,
                onJoin: () => rejoinTeacherMeeting(ref, context, meetings[i]),
              ),
            ],
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _OngoingMeetingCardShell extends StatelessWidget {
  const _OngoingMeetingCardShell({
    required this.title,
    required this.subtitle,
    required this.startedAt,
    required this.onJoin,
  });

  final String title;
  final String subtitle;
  final DateTime startedAt;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onJoin,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.35),
            ),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.success.withValues(alpha: 0.08),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _LiveDot(),
                          const SizedBox(width: 6),
                          Text(
                            'مكالمة جارية',
                            style: AppFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        intl.DateFormat('yyyy/MM/dd hh:mm a').format(startedAt),
                        style: AppFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'انضمام',
                    style: AppFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
