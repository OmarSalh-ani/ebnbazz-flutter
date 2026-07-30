import 'package:masged_parent_app/app/models/app_role.dart';

import '../utils/chat_server_time.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isSentByMe;
  final int? studentId;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isSentByMe,
    this.studentId,
  });

  factory ChatMessage.fromApiJson(
    Map<String, dynamic> j, {
    required AppRole viewerRole,
  }) {
    final senderType = _byte(j['senderType'] ?? j['SenderType']);
    final isTeacher = senderType == 1;
    final isSentByMe =
        viewerRole == AppRole.parent ? !isTeacher : isTeacher;

    final idVal = j['id'] ?? j['Id'];
    final createdRaw = j['sentAt'] ?? j['SentAt'];

    final teacherId = j['teacherId'] ?? j['TeacherId'];
    final studentIdRaw = j['studentId'] ?? j['StudentId'];

    return ChatMessage(
      id: idVal?.toString() ?? '',
      senderId:
          senderType == 1 ? teacherId?.toString() ?? 'teacher' : 'parent',
      text: (j['messageText'] ?? j['MessageText'] ?? '').toString(),
      createdAt: parseChatServerTime(createdRaw),
      isSentByMe: isSentByMe,
      studentId: _intOrNull(studentIdRaw),
    );
  }

  static int? _intOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static int _byte(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
