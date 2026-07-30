import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/child_model.dart';
import 'students_provider.dart';

final studentProfileProvider =
    FutureProvider.family<ChildModel, String>((ref, studentId) async {
  return ref.read(studentsApiServiceProvider).getStudentProfile(studentId);
});
