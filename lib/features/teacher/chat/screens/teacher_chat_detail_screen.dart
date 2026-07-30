import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../../core/network/signalr_hub_connector.dart';

import 'package:masged_parent_app/app/models/app_role.dart';
import 'package:masged_parent_app/core/constants/app_constants.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/widgets/session_expired_dialog.dart';
import 'package:masged_parent_app/features/chat/providers/active_chat_conversation.dart';
import 'package:masged_parent_app/features/chat/models/chat_message_model.dart';
import 'package:masged_parent_app/features/video_call/models/video_call_participant.dart';
import 'package:masged_parent_app/features/video_call/models/video_call_session.dart';
import 'package:masged_parent_app/features/video_call/providers/video_call_providers.dart';
import 'package:masged_parent_app/features/video_call/screens/agora_video_call_screen.dart';
import '../../../chat/widgets/chat_conversation_scaffold.dart';
import '../../../chat/widgets/chat_thread_app_bar_title.dart';
import '../models/parent_chat_thread_vm.dart';
import '../providers/teacher_chat_providers.dart';

/// Teacher ↔ parent thread keyed by (studentId, teacherId).
class TeacherChatDetailScreen extends ConsumerStatefulWidget {
  const TeacherChatDetailScreen({super.key, required this.thread});

  final ParentChatThreadVm thread;

  @override
  ConsumerState<TeacherChatDetailScreen> createState() =>
      _TeacherChatDetailScreenState();
}

class _TeacherChatDetailScreenState
    extends ConsumerState<TeacherChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  HubConnection? _hub;
  bool _loadingHistory = true;
  String? _error;

  int get _studentId => widget.thread.studentId;
  int get _teacherId => widget.thread.teacherId;

  @override
  void initState() {
    super.initState();
    ActiveChatConversationTracker.set(
      teacherId: _teacherId,
      studentId: _studentId,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await ref.read(authControllerProvider.future);
    if (!mounted) return;

    if (user == null || !user.isSessionValid) {
      setState(() => _loadingHistory = false);
      await showTeacherSessionExpiredDialog(context, ref);
      return;
    }

    if (user.id != _teacherId) {
      setState(() {
        _loadingHistory = false;
        _error = 'محادثة غير متطابقة مع المعلّم الحالي.';
      });
      return;
    }

    if (_studentId <= 0) {
      setState(() {
        _loadingHistory = false;
        _error = 'معرف الطالب غير صالح.';
      });
      return;
    }

    await _loadHistory();
    await _setupHub(user);
    await _markRead();
  }

  Future<void> _markRead() async {
    final api = ref.read(teacherChatApiProvider);
    unawaited(
      api.markReadRest(studentId: _studentId, teacherId: _teacherId),
    );
    try {
      if (_hub?.state == HubConnectionState.Connected) {
        await _hub!.invoke('markConversationRead', args: [
          _studentId,
          _teacherId,
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
      final api = ref.read(teacherChatApiProvider);
      final list = await api.getMessages(
        studentId: _studentId,
        teacherId: _teacherId,
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

  Future<void> _setupHub(AuthUser user) async {
    try {
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.chatHubPath}'.trim();

      final hub = await SignalRHubConnector.connect(
        hubUrl: url,
        accessTokenFactory: () async => user.token,
      );

      hub.on('receiveMessage', _onReceiveMessage);
      if (!mounted) {
        await hub.stop();
        return;
      }
      _hub = hub;

      await hub.invoke('joinConversation', args: [
        _studentId,
        _teacherId,
      ]);
    } catch (_) {
      /* REST fallback still works */
    }
  }

  void _onReceiveMessage(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is! Map) return;
    final m = Map<String, dynamic>.from(raw);
    final msgStudentId = ChatMessage.fromApiJson(m, viewerRole: AppRole.teacher)
        .studentId;
    if (msgStudentId != null && msgStudentId != _studentId) return;

    final msg = ChatMessage.fromApiJson(m, viewerRole: AppRole.teacher);
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

    final api = ref.read(teacherChatApiProvider);
    final payload = <String, dynamic>{
      'messageText': text,
      'studentId': _studentId,
    };

    try {
      if (_hub?.state == HubConnectionState.Connected) {
        final res = await _hub!.invoke('sendConversationMessage', args: [
          payload,
          _studentId,
          _teacherId,
        ]);
        if (res is Map) {
          final msg = ChatMessage.fromApiJson(
            Map<String, dynamic>.from(res),
            viewerRole: AppRole.teacher,
          );
          if (mounted &&
              !_messages.any((x) => x.id == msg.id || x.text == msg.text)) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          }
        }
        _messageController.clear();
      } else {
        await api.sendMessageRest(
          studentId: _studentId,
          teacherId: _teacherId,
          text: text,
        );
        _messageController.clear();
        await _loadHistory();
      }
    } catch (_) {
      try {
        await api.sendMessageRest(
          studentId: _studentId,
          teacherId: _teacherId,
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

  Future<void> _startVideoCall() async {
    if (_studentId <= 0) return;

    final user = await ref.read(authControllerProvider.future);
    final jwt = user?.token;
    if (!mounted) return;
    if (jwt == null || jwt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تسجيل الدخول مجدداً.',
            style: AppFonts.cairo(),
          ),
        ),
      );
      return;
    }

    final studentName = widget.thread.studentName?.trim();
    final displayName = studentName != null && studentName.isNotEmpty
        ? studentName
        : widget.thread.title;

    try {
      final created = await ref.read(videoCallApiProvider).createCall(
            meetingName: 'مكالمة — $displayName',
            studentIds: [_studentId],
            sendWhatsApp: true,
            teacherName: user?.name,
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AgoraVideoCallScreen(
            hubJwt: jwt,
            session: VideoCallSession.teacher(
              channelName: created.channelName,
              token: created.token,
              uid: created.uid,
              meetingId: created.id,
              displayTitle: displayName,
              startDateTime: DateTime.now(),
              participantsByStudentId: {
                _studentId: VideoCallParticipantInfo(
                  studentId: _studentId,
                  fullName: displayName,
                ),
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), style: AppFonts.cairo())),
      );
    }
  }

  Future<void> _teardownHub() async {
    final hub = _hub;
    _hub = null;
    if (hub == null) return;
    try {
      await hub.invoke('leaveConversation', args: [
        _studentId,
        _teacherId,
      ]);
    } catch (_) {}
    try {
      await hub.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread.title.trim();
    final studentLabel = widget.thread.studentName?.trim();
    final subtitle = studentLabel != null && studentLabel.isNotEmpty
        ? 'ولي أمر • ${widget.thread.canonicalParentPhone}'
        : widget.thread.canonicalParentPhone;

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
          title: widget.thread.title,
          subtitle: subtitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.videocam_outlined,
              color: AppColors.textPrimary,
            ),
            tooltip: 'مكالمة فيديو',
            onPressed: _startVideoCall,
          ),
        ],
      ),
      loadingHistory: _loadingHistory,
      messages: _messages,
      scrollController: _scrollController,
      messageController: _messageController,
      errorMessage: _error,
      onSend: _sendMessage,
    );
  }
}
