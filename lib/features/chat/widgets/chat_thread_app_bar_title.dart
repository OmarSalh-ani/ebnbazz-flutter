import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// AppBar titles receive unbounded horizontal width; [Expanded] inside [Row]
/// requires a bounded parent. This widget constrains the title row correctly.
class ChatThreadAppBarTitle extends StatelessWidget {
  const ChatThreadAppBarTitle({
    super.key,
    required this.avatarInitial,
    required this.title,
    required this.subtitle,
  });

  final String avatarInitial;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 96;

    return SizedBox(
      width: maxWidth,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              avatarInitial,
              style: AppFonts.cairo(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
