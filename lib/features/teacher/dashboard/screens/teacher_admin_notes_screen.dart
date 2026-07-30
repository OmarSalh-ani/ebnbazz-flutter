import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:masged_parent_app/core/theme/app_colors.dart';

import '../providers/dashboard_providers.dart';

import '../providers/teacher_admin_notes_provider.dart';

import '../widgets/dashboard_widgets/teacher_admin_note_card.dart';



class TeacherAdminNotesScreen extends ConsumerWidget {

  const TeacherAdminNotesScreen({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final notesAsync = ref.watch(teacherAdminNotesProvider);



    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(

        title: Text(

          'إشعارات الإدارة',

          style: AppFonts.cairo(fontWeight: FontWeight.bold),

        ),

        actions: [

          notesAsync.maybeWhen(

            data: (items) {

              final hasUnread = items.any((n) => !n.isRead);

              if (!hasUnread) return const SizedBox.shrink();

              return TextButton(

                onPressed: () async {

                  try {

                    await ref.read(teacherAdminNotesApiProvider).markAllRead();

                    ref.invalidate(teacherAdminNotesProvider);

                    ref.invalidate(dashboardPageProvider);

                    if (context.mounted) {

                      ScaffoldMessenger.of(context).showSnackBar(

                        SnackBar(

                          content: Text(

                            'تم تعليم الملاحظات كمقروءة',

                            style: AppFonts.cairo(),

                          ),

                        ),

                      );

                    }

                  } catch (_) {

                    if (context.mounted) {

                      ScaffoldMessenger.of(context).showSnackBar(

                        SnackBar(

                          content: Text(

                            'تعذر تحديث الحالة',

                            style: AppFonts.cairo(),

                          ),

                        ),

                      );

                    }

                  }

                },

                child: Text(

                  'تعليم الكل مقروء',

                  style: AppFonts.cairo(

                    fontWeight: FontWeight.bold,

                    fontSize: 13,

                  ),

                ),

              );

            },

            orElse: () => const SizedBox.shrink(),

          ),

        ],

      ),

      body: notesAsync.when(

        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(child: Text(e.toString())),

        data: (items) {

          if (items.isEmpty) {

            return Center(

              child: Text(

                'لا توجد ملاحظات',

                style: AppFonts.cairo(

                  fontSize: 16,

                  color: AppColors.textSecondary,

                ),

              ),

            );

          }

          return RefreshIndicator(

            onRefresh: () async => ref.invalidate(teacherAdminNotesProvider),

            child: ListView.separated(

              padding: const EdgeInsets.all(16),

              itemCount: items.length,

              separatorBuilder: (_, __) => const SizedBox(height: 12),

              itemBuilder: (context, i) => TeacherAdminNoteCard(note: items[i]),

            ),

          );

        },

      ),

    );

  }

}

