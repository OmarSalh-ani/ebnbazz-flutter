import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../models/parent_chat_thread_vm.dart';
import '../providers/teacher_chat_providers.dart';
import 'teacher_chat_detail_screen.dart';

/// Lists parent threads for the signed-in teacher (Teacher API REST).
class ParentChatListScreen extends ConsumerWidget {
  const ParentChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherChatThreadsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'محادثات أولياء الأمور',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'تعذر تحميل المحادثات',
                style: AppFonts.cairo(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (threads) => _threadsBody(context, threads, ref),
        ),
      ),
    );
  }

  Widget _threadsBody(
    BuildContext context,
    List<ParentChatThreadVm> threads,
    WidgetRef ref,
  ) {
    if (threads.isEmpty) {
      return Center(
        child: Text(
          'لا توجد محادثات بعد',
          style: AppFonts.cairo(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(teacherChatThreadsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: threads.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.border, indent: 72),
        itemBuilder: (context, i) {
          final t = threads[i];
          final name = t.title;
          final initial =
              name.trim().isNotEmpty ? name.trim().substring(0, 1) : '?';
          final parentLine = t.parentDisplayName?.trim();
          final subtitleParts = <String>[
            if (parentLine != null && parentLine.isNotEmpty) parentLine,
            t.subtitle,
          ];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                initial,
                style: AppFonts.cairo(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              style: AppFonts.cairo(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              subtitleParts.join(' • '),
              style: AppFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: t.unreadCount > 0
                ? Badge(
                    label: Text('${t.unreadCount}', style: const TextStyle(fontSize: 12)),
                  )
                : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TeacherChatDetailScreen(thread: t),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
