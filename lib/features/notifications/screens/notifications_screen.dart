import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/theme/app_colors.dart';
import '../../video_call/utils/parent_video_call_launcher.dart';
import '../models/parent_notification_item.dart';
import '../providers/parent_notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإشعارات',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: AppFonts.cairo(color: AppColors.error),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(parentNotificationsProvider),
                  child: Text('إعادة المحاولة', style: AppFonts.cairo()),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'لا توجد إشعارات حالياً',
                style: AppFonts.cairo(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(parentNotificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _NotificationTile(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final ParentNotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = item.kind == 'meet' ? Icons.videocam_rounded : Icons.newspaper;
    final isJoinableMeet = item.kind == 'meet' && item.canJoin;
    final isEndedMeet = item.isEndedMeeting;

    return Material(
      color: isEndedMeet ? AppColors.inputFill : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isJoinableMeet
            ? () => openParentVideoCallFromMeeting(
                  ref,
                  item.id,
                  startDateTime: item.createdAt,
                )
            : null,
        child: Opacity(
          opacity: isEndedMeet ? 0.75 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isEndedMeet
                        ? AppColors.textSecondary.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isEndedMeet
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
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
                              item.title,
                              style: AppFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isEndedMeet
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.schedule,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            intl.DateFormat('yyyy/MM/dd hh:mm a')
                                .format(item.createdAt),
                            style: AppFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.summary,
                        style: AppFonts.cairo(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (isJoinableMeet) ...[
                        const SizedBox(height: 8),
                        Text(
                          'اضغط للانضمام للمكالمة',
                          style: AppFonts.cairo(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      if (isEndedMeet) ...[
                        const SizedBox(height: 8),
                        Text(
                          'انتهت المكالمة',
                          style: AppFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
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
