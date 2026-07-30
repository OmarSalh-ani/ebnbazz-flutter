import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../children/models/child_model.dart';
import '../../children/providers/students_provider.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import '../models/chat_teacher_thread.dart';
import '../providers/chat_providers.dart';

class ChatTeachersScreen extends ConsumerWidget {
  const ChatTeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncThreads = ref.watch(chatTeacherThreadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'محادثة المعلمين',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: asyncThreads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذر تحميل قائمة المعلمين',
              style: AppFonts.cairo(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد معلمون متاحون للمحادثة',
                style: AppFonts.cairo(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      thread.teacherName.trim().isNotEmpty
                          ? thread.teacherName.trim().substring(0, 1)
                          : '?',
                      style: AppFonts.cairo(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    thread.teacherName,
                    style: AppFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    thread.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _openChat(context, ref, thread),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, WidgetRef ref, ChatTeacherThread thread) {
    final children = ref.read(studentsProvider).valueOrNull ?? [];
    final forTeacher = children
        .where((c) => int.tryParse(c.teacherId ?? '') == thread.teacherId)
        .toList();

    final ChildModel selected;
    if (forTeacher.isNotEmpty) {
      selected = forTeacher.firstWhere(
        (c) => int.tryParse(c.id) == thread.studentId,
        orElse: () => forTeacher.first,
      );
    } else {
      selected = ChildModel(
        id: '${thread.studentId}',
        name: thread.studentName,
        level: '',
        group: thread.subtitle,
        attendancePercent: 0,
        nextSession: '',
        status: ChildStatus.inMasged,
      );
    }

    final studentId = int.tryParse(selected.id) ?? thread.studentId;
    final detailThread = thread.copyWith(
      studentId: studentId,
      studentName: selected.name,
      subtitle: selected.group,
    );

    context.push(
      AppRoutes.chatDetailPath('${thread.teacherId}', '$studentId'),
      extra: detailThread,
    );
  }
}
