class ActiveChatConversation {
  const ActiveChatConversation({
    required this.teacherId,
    required this.studentId,
  });

  final int teacherId;
  final int studentId;

  bool matches({required int teacherId, required int studentId}) =>
      this.teacherId == teacherId && this.studentId == studentId;
}

/// Tracks the chat thread currently visible on screen (parent or teacher).
/// Uses a static holder so we never mutate Riverpod state during mount/dispose.
class ActiveChatConversationTracker {
  ActiveChatConversationTracker._();

  static ActiveChatConversation? _current;

  static void set({required int teacherId, required int studentId}) {
    _current = ActiveChatConversation(
      teacherId: teacherId,
      studentId: studentId,
    );
  }

  static void clear() {
    _current = null;
  }

  static bool isActive({required int teacherId, required int studentId}) {
    final current = _current;
    return current != null &&
        current.matches(teacherId: teacherId, studentId: studentId);
  }
}
