import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../../data/teacher_admin_notes_api.dart';

class TeacherAdminNoteCard extends StatelessWidget {
  const TeacherAdminNoteCard({
    super.key,
    required this.note,
  });

  final TeacherAdminNoteItem note;

  @override
  Widget build(BuildContext context) {
    final isRead = note.isRead;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead
              ? AppColors.border
              : AppColors.warning.withValues(alpha: 0.45),
          width: isRead ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.createdAtFormatted,
                  style: AppFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _ReadStatusChip(isRead: isRead),
            ],
          ),
          if (isRead && note.readTimeFormatted != null) ...[
            const SizedBox(height: 4),
            Text(
              'قُرئ في ${note.readTimeFormatted}',
              style: AppFonts.cairo(
                fontSize: 10,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            note.note,
            style: AppFonts.cairo(
              fontSize: 14,
              height: 1.5,
              color: isRead
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadStatusChip extends StatelessWidget {
  const _ReadStatusChip({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isRead ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRead ? Icons.done_all : Icons.mark_email_unread_outlined,
            size: 12,
            color: isRead ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isRead ? 'مقروء' : 'جديد',
            style: AppFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isRead ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
