import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/theme/app_colors.dart';
import '../models/chat_message_model.dart';
import '../utils/chat_server_time.dart';

/// Shared scaffold body for parent and teacher realtime chat threads.
class ChatConversationScaffold extends StatelessWidget {
  const ChatConversationScaffold({
    super.key,
    required this.appBar,
    required this.loadingHistory,
    required this.messages,
    required this.scrollController,
    required this.messageController,
    required     this.errorMessage,
    required this.onSend,
    this.inputHeader,
  });

  final PreferredSizeWidget appBar;
  final bool loadingHistory;
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final String? errorMessage;
  final VoidCallback onSend;
  final Widget? inputHeader;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: Column(
          children: [
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  errorMessage!,
                  style: AppFonts.cairo(color: AppColors.error, fontSize: 12),
                ),
              ),
            Expanded(
              child: loadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final showDate = index == 0 ||
                            !isSameChatDay(
                              message.createdAt,
                              messages[index - 1].createdAt,
                            );

                        return Column(
                          children: [
                            if (showDate)
                              ChatDateSeparator(date: message.createdAt),
                            ChatMessageBubble(
                              message: message,
                              maxBubbleWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                          ],
                        );
                      },
                    ),
            ),
            if (inputHeader != null) inputHeader!,
            ChatMessageInputArea(
              messageController: messageController,
              onSend: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

bool isSameChatDay(DateTime d1, DateTime d2) =>
    d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

String formatChatDateHeader(DateTime date) {
  final today = kuwaitServerToday();
  if (isSameChatDay(date, today)) return 'اليوم';
  if (isSameChatDay(date, today.subtract(const Duration(days: 1)))) {
    return 'أمس';
  }
  return intl.DateFormat('d MMMM yyyy', 'ar').format(date);
}

class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            formatChatDateHeader(date),
            style: AppFonts.cairo(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.maxBubbleWidth,
  });

  final ChatMessage message;
  final double maxBubbleWidth;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppFonts.cairo(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                intl.DateFormat('hh:mm a').format(message.createdAt),
                style: AppFonts.cairo(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: isMe ? 0.2 : -0.2),
    );
  }
}

class ChatMessageInputArea extends StatelessWidget {
  const ChatMessageInputArea({
    super.key,
    required this.messageController,
    required this.onSend,
  });

  final TextEditingController messageController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: TextField(
                controller: messageController,
                style: AppFonts.cairo(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك هنا...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
