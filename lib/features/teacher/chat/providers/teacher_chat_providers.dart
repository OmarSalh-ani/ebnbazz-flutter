import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/teacher_chat_api.dart';
import '../models/parent_chat_thread_vm.dart';

final teacherChatApiProvider = Provider<TeacherChatApi>((ref) {
  return TeacherChatApi(ref.watch(apiClientProvider));
});

final teacherChatThreadsProvider =
    FutureProvider.autoDispose<List<ParentChatThreadVm>>((ref) async {
  final auth = await ref.watch(authControllerProvider.future);
  if (auth == null) return [];

  final api = ref.watch(teacherChatApiProvider);
  return api.getConversations();
});
