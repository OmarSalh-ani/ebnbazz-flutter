import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/student_plan_api.dart';
import '../data/student_plan_repository.dart';
import '../models/student_plan_models.dart';

final studentPlanApiProvider = Provider<StudentPlanApi>((ref) {
  return StudentPlanApi(ref.watch(apiClientProvider));
});

final studentPlanRepositoryProvider = Provider<StudentPlanRepository>((ref) {
  return StudentPlanRepository(ref.watch(studentPlanApiProvider));
});

final planFormDataProvider = FutureProvider.autoDispose<PlanFormData>((ref) {
  return ref.watch(studentPlanRepositoryProvider).getFormData();
});

final studentPlanOverviewProvider =
    FutureProvider.autoDispose.family<StudentPlanOverview, int>((ref, studentId) {
  return ref.watch(studentPlanRepositoryProvider).getOverview(studentId);
});

final studentPlanDetailProvider = FutureProvider.autoDispose
    .family<StudentPlanDetail, StudentPlanDetailKey>((ref, key) {
  return ref
      .watch(studentPlanRepositoryProvider)
      .getPlanDetail(key.studentId, key.planId);
});

class StudentPlanDetailKey {
  const StudentPlanDetailKey({required this.studentId, required this.planId});

  final int studentId;
  final int planId;

  @override
  bool operator ==(Object other) =>
      other is StudentPlanDetailKey &&
      other.studentId == studentId &&
      other.planId == planId;

  @override
  int get hashCode => Object.hash(studentId, planId);
}

final surahAyahsProvider = FutureProvider.autoDispose
    .family<List<int>, int>((ref, surahId) {
  return ref.watch(studentPlanRepositoryProvider).getAyahNumbers(surahId);
});
