import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../children/models/child_model.dart';
import '../../children/providers/students_provider.dart';
import '../models/chat_teacher_thread.dart';
import '../services/chat_api_service.dart';

final chatApiServiceProvider = Provider((ref) => ChatApiService());

/// Teacher rows for chat: merges `/api/chat/conversations` with children fallback.
/// List UI shows one row per teacher; detail screen selects student thread.
final chatTeacherThreadsProvider =
    FutureProvider.autoDispose<List<ChatTeacherThread>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    return const [];
  }

  final canon = authState.user!.phone;

  final conversations =
      await ref.read(chatApiServiceProvider).getConversations();

  final children = await ref.watch(studentsProvider.future);

  final threads = <int, ChatTeacherThread>{};

  for (final c in conversations) {
    if (c.teacherId <= 0 || c.studentId <= 0 || c.parentPhone.isEmpty) {
      continue;
    }

    if (threads.containsKey(c.teacherId)) {
      final existing = threads[c.teacherId]!;
      final names = _mergeStudentNames(existing.studentName, c.studentName);
      threads[c.teacherId] = existing.copyWith(
        studentName: names,
        subtitle: _teacherListSubtitle(
          preview: c.lastMessagePreview,
          unread: c.unreadCount,
          studentNames: names,
        ),
      );
    } else {
      threads[c.teacherId] = c.toThread();
    }
  }

  final byTeacher = <int, List<ChildModel>>{};
  for (final child in children) {
    final tidStr = child.teacherId;
    if (tidStr == null || tidStr.isEmpty) continue;
    final tid = int.tryParse(tidStr);
    if (tid == null) continue;
    byTeacher.putIfAbsent(tid, () => []).add(child);
  }

  for (final entry in byTeacher.entries) {
    final tid = entry.key;
    if (threads.containsKey(tid)) continue;

    final kids = entry.value;
    if (kids.isEmpty) continue;
    final first = kids.first;
    final names = kids.map((c) => c.firstName).join('، ');
    final studentId = int.tryParse(first.id);
    if (studentId == null) continue;

    threads[tid] = ChatTeacherThread(
      teacherId: tid,
      studentId: studentId,
      teacherName: first.teacherName ?? 'معلم',
      studentName: first.name,
      subtitle: '${first.group} • $names',
      canonicalParentPhone: canon,
    );
  }

  final list = threads.values.toList()
    ..sort((a, b) => a.teacherName.compareTo(b.teacherName));
  return list;
});

String _mergeStudentNames(String existing, String? incoming) {
  final parts = <String>{};
  for (final raw in [existing, incoming ?? '']) {
    for (final piece in raw.split('،')) {
      final trimmed = piece.trim();
      if (trimmed.isNotEmpty) parts.add(trimmed);
    }
  }
  return parts.join('، ');
}

String _teacherListSubtitle({
  required String? preview,
  required int unread,
  required String studentNames,
}) {
  final p = preview?.trim();
  if (p != null && p.isNotEmpty) {
    return '$p${unread > 0 ? ' • ($unread)' : ''}';
  }
  if (studentNames.isNotEmpty) {
    return unread > 0 ? '$studentNames • $unread غير مقروء' : studentNames;
  }
  return unread > 0 ? '$unread غير مقروء' : '';
}

/// Children enrolled with a specific teacher (for chat detail child selector).
final chatChildrenForTeacherProvider =
    Provider.family<List<ChildModel>, int>((ref, teacherId) {
  final childrenAsync = ref.watch(studentsProvider);
  return childrenAsync.maybeWhen(
    data: (children) => children
        .where((c) => int.tryParse(c.teacherId ?? '') == teacherId)
        .toList(),
    orElse: () => const [],
  );
});
