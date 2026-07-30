import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import 'package:masged_parent_app/shared/widgets/custom_text_field.dart';
import '../../shared/models/selectable_student_row.dart';
import '../../shared/widgets/selectable_students_list.dart';
import '../../../teacher/attendance/providers/attendance_providers.dart';
import '../../../teacher/auth/providers/auth_providers.dart';
import '../../../teacher/dashboard/models/dashboard_models.dart';
import '../../../video_call/models/video_call_models.dart';
import '../../../video_call/models/video_call_session.dart';
import '../../../video_call/providers/video_call_providers.dart';
import '../../../video_call/screens/agora_video_call_screen.dart';
import '../../../video_call/utils/video_call_participant_utils.dart';

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  final _nameController = TextEditingController(text: 'مجموعة حلقة القرآن');
  final Set<int> _selectedIds = {};
  String? _teacherName;
  bool _saving = false;
  bool _sendWhatsApp = true;

  Future<String?> _requireTeacherJwt() async {
    final user = await ref.read(authControllerProvider.future);
    final t = user?.token;
    if (t == null || t.isEmpty) return null;
    return t;
  }

  Future<void> _startNewCall() async {
    final jwt = await _requireTeacherJwt();
    if (!mounted) return;
    if (jwt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتهت الجلسة.', style: AppFonts.cairo())),
      );
      return;
    }

    final ids = _selectedIds.toList();

    final students = ref.read(attendanceStudentsProvider).value ?? const [];
    final participants = participantsForStudents(students, ids);

    final authUser = await ref.read(authControllerProvider.future);
    _teacherName ??= authUser?.name;

    setState(() => _saving = true);
    try {
      final created = await ref.read(videoCallApiProvider).createCall(
            meetingName: _nameController.text.trim(),
            studentIds: ids,
            sendWhatsApp: _sendWhatsApp,
            teacherName: _teacherName,
          );
      ref.invalidate(videoCallMeetingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(created.message, style: AppFonts.cairo()),
        ),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AgoraVideoCallScreen(
            hubJwt: jwt,
            session: VideoCallSession.teacher(
              channelName: created.channelName,
              token: created.token,
              uid: created.uid,
              meetingId: created.id,
              displayTitle: created.meetingName,
              startDateTime: DateTime.now(),
              participantsByStudentId: participants,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _rejoinMeeting(VideoCallListRow row) async {
    if (row.isEnded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'انتهت هذه المكالمة ولا يمكن الانضمام إليها.',
              style: AppFonts.cairo(),
            ),
          ),
        );
      }
      return;
    }
    final jwt = await _requireTeacherJwt();
    if (!mounted) return;
    if (jwt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتهت الجلسة.', style: AppFonts.cairo())),
      );
      return;
    }
    try {
      final tok = await ref.read(videoCallApiProvider).refreshToken(row.id);
      final students = ref.read(attendanceStudentsProvider).value ?? const [];
      final participants = participantsFromMeetingRow(row, students);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AgoraVideoCallScreen(
            hubJwt: jwt,
            session: VideoCallSession.teacher(
              channelName: tok.channelName,
              token: tok.token,
              uid: tok.uid,
              meetingId: row.id,
              displayTitle: row.meetingName,
              startDateTime: row.startDateTime,
              participantsByStudentId: participants,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(attendanceStudentsProvider);
    final meetingsAsync = ref.watch(videoCallMeetingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'مكالمات الفيديو',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceStudentsProvider);
          ref.invalidate(videoCallMeetingsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              meetingsAsync.when(
                loading: () => const SizedBox(height: 8),
                error: (e, _) => Text(e.toString(),
                    style: AppFonts.cairo(color: AppColors.error)),
                data: (_) => const SizedBox.shrink(),
              ),
              _buildCreateSection(),
              const SizedBox(height: 16),
              studentsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) =>
                    Text(e.toString(), style: AppFonts.cairo()),
                data: _buildStudentSection,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text('إرسال واتساب للطلاب المحددين',
                    style: AppFonts.cairo()),
                value: _sendWhatsApp,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _sendWhatsApp = v),
              ),
              CustomButton(
                text: 'بدء المكالمة الآن',
                onPressed: _startNewCall,
                isLoading: _saving,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    'المكالمات المحفوظة',
                    style: AppFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => ref.invalidate(videoCallMeetingsProvider),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              meetingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(e.toString()),
                data: _buildMeetingsList,
              ),
            ],
          ),
        ),
      ),
    );
  }

 

  Widget _buildCreateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات المكالمة',
            style: AppFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'اسم المكالمة',
            hint: 'أدخل الاسم',
            controller: _nameController,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSection(List<StudentListItem> students) {
    final rows = students
        .map(
          (s) => SelectableStudentRow(
            id: s.id,
            name: s.name,
            imageUrl: s.imageUrl,
          ),
        )
        .toList();

    return SelectableStudentsList(
      title: 'اختر الطلاب للمكالمة',
      students: rows,
      selectedIds: _selectedIds,
      onSelectionChanged: (id, selected) {
        setState(() {
          if (selected) {
            _selectedIds.add(id);
          } else {
            _selectedIds.remove(id);
          }
        });
      },
      emptyMessage: 'لا يوجد طلاب مسجلون في حلقتك',
    );
  }

  Widget _buildMeetingsList(List<VideoCallListRow> rows) {
    if (rows.isEmpty) {
      return Text(
        'لا توجد مكالمات محفوظة بعد.',
        style: AppFonts.cairo(color: AppColors.textSecondary),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final m = rows[index];
        final isEnded = m.isEnded;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEnded ? AppColors.inputFill : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isEnded
                ? Border.all(color: AppColors.border)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      m.meetingName,
                      style: AppFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEnded
                          ? AppColors.textSecondary.withValues(alpha: 0.12)
                          : AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isEnded ? 'منتهية' : 'نشطة',
                      style: AppFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isEnded ? AppColors.textSecondary : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isEnded && m.endedAt != null
                    ? 'انتهت ${intl.DateFormat('yyyy/MM/dd hh:mm a').format(m.endedAt!)}'
                    : intl.DateFormat('yyyy/MM/dd hh:mm a')
                        .format(m.startDateTime),
                style: AppFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (m.studentNames.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  m.studentNames,
                  style: AppFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (isEnded &&
                  m.teacherNotes != null &&
                  m.teacherNotes!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملاحظات المكالمة',
                        style: AppFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.teacherNotes!.trim(),
                        style: AppFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!isEnded) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'انضمام',
                        height: 40,
                        onPressed: () => _rejoinMeeting(m),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'حذف',
                      onPressed: () async {
                        try {
                          await ref
                              .read(videoCallApiProvider)
                              .deleteMeeting(m.id);
                          ref.invalidate(videoCallMeetingsProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم الحذف',
                                  style: AppFonts.cairo(),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
