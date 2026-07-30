import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/teacher_admin_notes_api.dart';

final teacherAdminNotesApiProvider = Provider<TeacherAdminNotesApi>((ref) {
  return TeacherAdminNotesApi(ref.watch(apiClientProvider));
});

final teacherAdminNotesProvider =
    FutureProvider.autoDispose<List<TeacherAdminNoteItem>>((ref) async {
  return ref.watch(teacherAdminNotesApiProvider).fetchAll();
});
