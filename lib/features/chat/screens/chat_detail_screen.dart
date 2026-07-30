import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/network/signalr_hub_connector.dart';

import 'package:masged_parent_app/app/models/app_role.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../children/models/child_model.dart';
import '../../../shared/widgets/student_avatar.dart';
import '../models/chat_message_model.dart';
import '../models/chat_teacher_thread.dart';
import '../providers/active_chat_conversation.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_conversation_scaffold.dart';
import '../widgets/chat_thread_app_bar_title.dart';

/// Realtime chat with a teacher via Parent API SignalR (`/hubs/chat`) + REST fallback.
class ChatDetailScreen extends ConsumerStatefulWidget {
  final ChatTeacherThread thread;

  const ChatDetailScreen({super.key, required this.thread});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  static const double _childSelectorHeight = 96;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  HubConnection? _hub;
  bool _loadingHistory = true;
  String? _error;

  late int _activeStudentId;
  late String _activeStudentName;
  late String _activeSubtitle;

  @override
  void initState() {
    super.initState();
    _activeStudentId = widget.thread.studentId;
    _activeStudentName = widget.thread.studentName;
    _activeSubtitle = widget.thread.subtitle;
    _markActiveConversation();
    _bootstrap();
  }

  void _markActiveConversation() {
    ActiveChatConversationTracker.set(
      teacherId: widget.thread.teacherId,
      studentId: _activeStudentId,
    );
  }

  List<ChildModel> _childrenForTeacher(WidgetRef ref) =>
      ref.watch(chatChildrenForTeacherProvider(widget.thread.teacherId));

  Future<void> _bootstrap() async {
    await _loadHistory();
    await _setupHub();
    await _markRead();
  }

  Future<void> _markRead() async {
    unawaited(
      ref.read(chatApiServiceProvider).markReadRest(
            teacherId: widget.thread.teacherId,
            studentId: _activeStudentId,
          ),
    );
    try {
      if (_hub?.state == HubConnectionState.Connected) {
        await _hub!.invoke('markConversationRead', args: [
          _activeStudentId,
          widget.thread.teacherId,
        ]);
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _error = null;
    });
    try {
      final api = ref.read(chatApiServiceProvider);
      final list = await api.getMessages(
        teacherId: widget.thread.teacherId,
        studentId: _activeStudentId,
      );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _loadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingHistory = false;
        _error = 'تعذر تحميل الرسائل';
      });
    }
  }

  Future<void> _setupHub() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAuthToken);
      if (token == null || token.isEmpty) return;

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.chatHubPath}'.trim();

      final hub = await SignalRHubConnector.connect(
        hubUrl: url,
        accessTokenFactory: () async => token,
      );

      hub.on('receiveMessage', _onReceiveMessage);
      if (!mounted) {
        await hub.stop();
        return;
      }
      _hub = hub;

      await hub.invoke('joinConversation', args: [
        _activeStudentId,
        widget.thread.teacherId,
      ]);
    } catch (_) {
      /* Optional: REST still works */
    }
  }

  Future<void> _switchStudent(ChildModel child) async {
    final studentId = int.tryParse(child.id);
    if (studentId == null || studentId == _activeStudentId) return;

    await _teardownHub();

    setState(() {
      _activeStudentId = studentId;
      _activeStudentName = child.name;
      _activeSubtitle = child.group;
      _messages.clear();
      _loadingHistory = true;
    });
    _markActiveConversation();

    await _loadHistory();
    await _setupHub();
    await _markRead();
  }

  void _onReceiveMessage(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is! Map) return;
    final m = Map<String, dynamic>.from(raw);
    final msgStudentId =
        ChatMessage.fromApiJson(m, viewerRole: AppRole.parent).studentId;
    if (msgStudentId != null && msgStudentId != _activeStudentId) return;

    final msg = ChatMessage.fromApiJson(m, viewerRole: AppRole.parent);
    setState(() {
      if (!_messages.any((x) => x.id == msg.id)) {
        _messages.add(msg);
      }
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final api = ref.read(chatApiServiceProvider);
    final payload = <String, dynamic>{
      'messageText': text,
      'studentId': _activeStudentId,
    };

    try {
      if (_hub?.state == HubConnectionState.Connected) {
        final res = await _hub!.invoke('sendConversationMessage', args: [
          payload,
          _activeStudentId,
          widget.thread.teacherId,
        ]);
        if (res is Map) {
          final msg =
              ChatMessage.fromApiJson(Map<String, dynamic>.from(res),
                  viewerRole: AppRole.parent);
          if (mounted &&
              !_messages.any((x) => x.id == msg.id || x.text == msg.text)) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          }
        }
        _messageController.clear();
      } else {
        await api.sendMessageRest(
          teacherId: widget.thread.teacherId,
          studentId: _activeStudentId,
          text: text,
        );
        _messageController.clear();
        await _loadHistory();
      }
    } catch (_) {
      try {
        await api.sendMessageRest(
          teacherId: widget.thread.teacherId,
          studentId: _activeStudentId,
          text: text,
        );
        _messageController.clear();
        await _loadHistory();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر إرسال الرسالة')),
          );
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    ActiveChatConversationTracker.clear();
    unawaited(_teardownHub());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _teardownHub() async {
    final hub = _hub;
    _hub = null;
    if (hub == null) return;
    try {
      await hub.invoke('leaveConversation', args: [
        _activeStudentId,
        widget.thread.teacherId,
      ]);
    } catch (_) {}
    try {
      await hub.stop();
    } catch (_) {}
  }

  Widget? _buildChildSelector() {
    final children = _childrenForTeacher(ref);
    if (children.length < 2) return null;

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SizedBox(
        height: _childSelectorHeight,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: children.length,
          separatorBuilder: (_, __) => const SizedBox(width: 20),
          itemBuilder: (context, index) => Align(
            alignment: Alignment.center,
            child: _buildChildChip(children[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildChildChip(ChildModel child) {
    final studentId = int.tryParse(child.id);
    final isSelected = studentId == _activeStudentId;
    return GestureDetector(
      onTap: () => _switchStudent(child),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: StudentAvatar(imageUrl: child.avatarUrl, size: 48),
            ),
            const SizedBox(height: 4),
            Text(
              child.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppFonts.cairo(
                fontSize: 12,
                height: 1.1,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread.teacherName.trim();
    final children = _childrenForTeacher(ref);
    final showChildSelector = children.length >= 2;
    final subtitle = showChildSelector
        ? '$_activeStudentName • $_activeSubtitle'
        : widget.thread.subtitle;

    return ChatConversationScaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: ChatThreadAppBarTitle(
          avatarInitial: t.isNotEmpty ? t.substring(0, 1) : '?',
          title: widget.thread.teacherName,
          subtitle: subtitle,
        ),
      ),
      loadingHistory: _loadingHistory,
      messages: _messages,
      scrollController: _scrollController,
      messageController: _messageController,
      errorMessage: _error,
      onSend: _sendMessage,
      inputHeader: _buildChildSelector(),
    );
  }
}
