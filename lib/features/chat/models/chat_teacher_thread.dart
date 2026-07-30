/// Target teacher + student context for SignalR-backed chat.
class ChatTeacherThread {
  final int teacherId;
  final int studentId;
  final String teacherName;
  final String studentName;
  final String subtitle;
  /// Kuwait-style canonical 8-digit key (matches API `fatherPhone` claim normalization).
  final String canonicalParentPhone;

  const ChatTeacherThread({
    required this.teacherId,
    required this.studentId,
    required this.teacherName,
    required this.studentName,
    required this.subtitle,
    required this.canonicalParentPhone,
  });

  ChatTeacherThread copyWith({
    int? studentId,
    String? studentName,
    String? subtitle,
  }) {
    return ChatTeacherThread(
      teacherId: teacherId,
      studentId: studentId ?? this.studentId,
      teacherName: teacherName,
      studentName: studentName ?? this.studentName,
      subtitle: subtitle ?? this.subtitle,
      canonicalParentPhone: canonicalParentPhone,
    );
  }
}
