import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/child_model.dart';
import '../services/students_api_service.dart';

final studentsApiServiceProvider = Provider((ref) => StudentsApiService());

final studentsProvider = FutureProvider<List<ChildModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];
  return ref.read(studentsApiServiceProvider).getStudents();
});

