import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/foreground_push_message.dart';
import '../../features/chat/utils/chat_notification_launcher.dart';
import '../../core/theme/app_colors.dart';

class ForegroundPushBanner extends ConsumerStatefulWidget {
  const ForegroundPushBanner({
    super.key,
    this.onMeetingTap,
    this.onChatTap,
  });

  final void Function(int meetingId)? onMeetingTap;
  final void Function(ChatPushTarget target)? onChatTap;

  @override
  ConsumerState<ForegroundPushBanner> createState() =>
      _ForegroundPushBannerState();
}

class _ForegroundPushBannerState extends ConsumerState<ForegroundPushBanner>
    with SingleTickerProviderStateMixin {
  Timer? _autoDismissTimer;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _scheduleAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 10), _dismiss);
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      ref.read(foregroundPushMessageProvider.notifier).state = null;
    }
  }

  void _onTap(ForegroundPushMessage message) {
    if (message.isMeeting) {
      final meetingId = message.meetingId;
      if (meetingId != null) {
        widget.onMeetingTap?.call(meetingId);
      }
    } else if (message.isChat) {
      final teacherId = message.teacherId;
      final studentId = message.studentId;
      if (teacherId != null && studentId != null) {
        widget.onChatTap?.call(
          ChatPushTarget(
            teacherId: teacherId,
            studentId: studentId,
            teacherName: message.teacherName,
            studentName: message.studentName,
            parentPhone: message.parentPhone,
          ),
        );
      }
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForegroundPushMessage?>(foregroundPushMessageProvider, (
      _,
      next,
    ) {
      if (next != null) {
        _slideController.forward(from: 0);
        _scheduleAutoDismiss();
      } else {
        _autoDismissTimer?.cancel();
        _slideController.reverse();
      }
    });

    final message = ref.watch(foregroundPushMessageProvider);
    if (message == null) {
      return const SizedBox.shrink();
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    final isMeeting = message.isMeeting;
    final isChat = message.isChat;

    return Positioned(
      top: 0,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.only(top: topPadding + 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMeeting || isChat
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                    InkWell(
                      onTap: () => _onTap(message),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: isMeeting || isChat
                                    ? AppColors.primaryGradient
                                    : null,
                                color: isMeeting || isChat
                                    ? null
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isMeeting
                                    ? Icons.videocam_rounded
                                    : isChat
                                        ? Icons.chat_bubble_rounded
                                        : Icons.notifications_active_rounded,
                                color: isMeeting || isChat
                                    ? Colors.white
                                    : AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isMeeting)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'مكالمة فيديو',
                                            style: AppFonts.cairo(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        )
                                      else if (isChat)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'رسالة جديدة',
                                            style: AppFonts.cairo(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          'مسجد مبارك',
                                          style: AppFonts.cairo(
                                            fontSize: 11,
                                            color: AppColors.textHint,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.title,
                                    style: AppFonts.cairo(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.body,
                                    style: AppFonts.cairo(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isMeeting || isChat) ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        isMeeting
                                            ? 'اضغط للانضمام'
                                            : 'اضغط لفتح المحادثة',
                                        style: AppFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _dismiss,
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: AppColors.textHint,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
