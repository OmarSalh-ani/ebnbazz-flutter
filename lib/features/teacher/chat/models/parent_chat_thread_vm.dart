import 'package:masged_parent_app/features/chat/utils/chat_server_time.dart';

class ParentChatThreadVm {
  final String canonicalParentPhone;
  final int teacherId;
  final int studentId;
  final String? studentName;
  final String? parentDisplayName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ParentChatThreadVm({
    required this.canonicalParentPhone,
    required this.teacherId,
    required this.studentId,
    this.studentName,
    this.parentDisplayName,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ParentChatThreadVm.fromJson(Map<String, dynamic> j) {
    final lastRaw = j['lastMessageAt'] ?? j['LastMessageAt'];

    return ParentChatThreadVm(
      canonicalParentPhone:
          (j['parentPhone'] ?? j['ParentPhone'] ?? '').toString(),
      teacherId: _int(j['teacherId'] ?? j['TeacherId']),
      studentId: _int(j['studentId'] ?? j['StudentId']),
      studentName: j['studentName'] ?? j['StudentName'] as String?,
      parentDisplayName:
          j['parentDisplayName'] ?? j['ParentDisplayName'] as String?,
      lastMessagePreview:
          j['lastMessagePreview'] ?? j['LastMessagePreview'] as String?,
      lastMessageAt: parseChatServerTimeOrNull(lastRaw),
      unreadCount: _int(j['unreadCount'] ?? j['UnreadCount']),
    );
  }

  String get title {
    final student = studentName?.trim();
    if (student != null && student.isNotEmpty) return student;
    final parent = parentDisplayName?.trim();
    if (parent != null && parent.isNotEmpty) return parent;
    return canonicalParentPhone;
  }

  String get subtitle {
    final preview = lastMessagePreview?.trim();
    if (preview != null && preview.isNotEmpty) return preview;
    if (lastMessageAt != null) {
      return 'آخر نشاط ${_formatBrief(lastMessageAt!)}';
    }
    return 'لا توجد رسائل بعد';
  }

  static String _formatBrief(DateTime d) {
    final today = kuwaitServerToday();
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${d.day}/${d.month}';
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
