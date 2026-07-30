import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/features/teacher/auth/providers/auth_providers.dart';
import 'package:masged_parent_app/features/video_call/models/video_call_participant.dart';
import 'package:masged_parent_app/features/video_call/models/video_call_session.dart';
import 'package:masged_parent_app/features/video_call/providers/video_call_providers.dart';
import 'package:masged_parent_app/features/video_call/screens/agora_video_call_screen.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import '../../../attendance/providers/attendance_providers.dart';
import '../../../students/providers/students_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../../chat/utils/open_student_parent_chat.dart';
import '../../../memorizing_archive/screens/teacher_memorizing_archive_screen.dart';
import '../../../plans/screens/student_plan_screen.dart';
import '../../../tests/screens/tests_screen.dart';
import '../../models/dashboard_models.dart';
import 'small_action_btn.dart';
import 'student_badge.dart';
import 'student_status_color.dart';

class StudentCard extends ConsumerWidget {
  const StudentCard({
    super.key,
    required this.student,
  });

  final StudentListItem student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = studentStatusColorFor(student.isPresentToday);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  backgroundImage: student.imageUrl != null
                      ? NetworkImage(student.imageUrl!)
                      : null,
                  child: student.imageUrl == null
                      ? Icon(Icons.person, color: statusColor, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.name,
                              style: AppFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (student.isSpecial)
                            const StudentBadge(
                              label: 'مميز',
                              color: AppColors.warning,
                            ),
                          if (student.isElite)
                            const StudentBadge(
                              label: 'نخبة',
                              color: AppColors.gold,
                            ),
                        ],
                      ),
                      Text(
                        '${student.group} - ${student.planLevelName}',
                        style: AppFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student.todayStatusLabel,
                    textAlign: TextAlign.center,
                    style: AppFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'إزالة من الحلقة',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => _confirmRemoveFromCircle(context, ref, student),
                  icon: const Icon(
                    Icons.person_remove_outlined,
                    size: 22,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SmallActionBtn(
                  title: 'أرشيف الحفظ',
                  icon: Icons.menu_book_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherMemorizingArchiveScreen(
                          studentId: student.id,
                          studentName: student.name,
                        ),
                      ),
                    );
                  },
                ),
                SmallActionBtn(
                  title: 'الاختبارات',
                  icon: Icons.assignment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TestsScreen(
                          studentId: student.id,
                          studentName: student.name,
                          planLevelName: student.planLevelName,
                        ),
                      ),
                    );
                  },
                ),
                SmallActionBtn(
                  title: 'الخطة',
                  icon: Icons.calendar_today,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentPlanScreen(
                          studentId: student.id,
                          studentName: student.name,
                          planLevelName: student.planLevelName,
                        ),
                      ),
                    );
                  },
                ),
                SmallActionBtn(
                  title: 'الملاحظات',
                  icon: Icons.chat,
                  onTap: () => openStudentParentChat(context, ref, student),
                ),
                SmallActionBtn(
                  title: 'مكالمة',
                  icon: Icons.videocam,
                  onTap: () => _startVideoCall(context, ref, student),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmRemoveFromCircle(
  BuildContext context,
  WidgetRef ref,
  StudentListItem student,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'تأكيد الإزالة',
        textAlign: TextAlign.right,
        style: AppFonts.cairo(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'هل تريد إزالة "${student.name}" من الحلقة؟',
        textAlign: TextAlign.right,
        style: AppFonts.cairo(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('إلغاء', style: AppFonts.cairo(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'إزالة',
            style: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    final message = await ref
        .read(studentsApiProvider)
        .removeStudentFromCircle(student.id);

    ref.read(dashboardPageProvider.notifier).refresh();
    ref.invalidate(attendanceStudentsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: AppFonts.cairo())),
      );
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: AppFonts.cairo()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception:', '').trim(),
            style: AppFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

Future<void> _startVideoCall(
  BuildContext context,
  WidgetRef ref,
  StudentListItem student,
) async {
  final user = await ref.read(authControllerProvider.future);
  final jwt = user?.token;
  if (!context.mounted) return;
  if (jwt == null || jwt.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('يرجى تسجيل الدخول مجدداً.', style: AppFonts.cairo())),
    );
    return;
  }

  try {
    final created = await ref.read(videoCallApiProvider).createCall(
          meetingName: 'مكالمة — ${student.name}',
          studentIds: [student.id],
          sendWhatsApp: true,
          teacherName: user?.name,
        );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgoraVideoCallScreen(
          hubJwt: jwt,
          session: VideoCallSession.teacher(
            channelName: created.channelName,
            token: created.token,
            uid: created.uid,
            meetingId: created.id,
            displayTitle: student.name,
            startDateTime: DateTime.now(),
            participantsByStudentId: {
              student.id: VideoCallParticipantInfo.fromStudent(
                studentId: student.id,
                name: student.name,
                imageUrl: student.imageUrl,
              ),
            },
          ),
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
