import 'chat_teacher_thread.dart';
import '../utils/chat_server_time.dart';

/// Server shape for `/api/chat/conversations` rows.
class ChatConversationVm {
  final int teacherId;
  final int studentId;
  final String? teacherName;
  final String? studentName;
  final String parentPhone;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatConversationVm({
    required this.teacherId,
    required this.studentId,
    required this.teacherName,
    required this.studentName,
    required this.parentPhone,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatConversationVm.fromJson(Map<String, dynamic> j) {
    final teacherIdRaw = j['teacherId'] ?? j['TeacherId'];
    final studentIdRaw = j['studentId'] ?? j['StudentId'];
    final parentRaw = j['parentPhone'] ?? j['ParentPhone'];
    final la = j['lastMessageAt'] ?? j['LastMessageAt'];

    return ChatConversationVm(
      teacherId: _asInt(teacherIdRaw)!,
      studentId: _asInt(studentIdRaw) ?? 0,
      teacherName: _asString(j['teacherName'] ?? j['TeacherName']),
      studentName: _asString(j['studentName'] ?? j['StudentName']),
      parentPhone: parentRaw?.toString() ?? '',
      lastMessagePreview:
          _asString(j['lastMessagePreview'] ?? j['LastMessagePreview']),
      lastMessageAt: parseChatServerTimeOrNull(la),
      unreadCount: _asInt(j['unreadCount'] ?? j['UnreadCount']) ?? 0,
    );
  }

  ChatTeacherThread toThread() {
    final preview = lastMessagePreview;
    final student = studentName?.trim();
    final sub = preview == null || preview.isEmpty
        ? '${student ?? ''}${unreadCount > 0 ? ' • $unreadCount غير مقروء' : ''}'
        : '$preview${unreadCount > 0 ? ' • ($unreadCount)' : ''}';
    return ChatTeacherThread(
      teacherId: teacherId,
      studentId: studentId,
      teacherName: teacherName ?? 'معلم',
      studentName: student ?? '',
      subtitle: sub.trim(),
      canonicalParentPhone: parentPhone,
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    return v.toString();
  }
}
