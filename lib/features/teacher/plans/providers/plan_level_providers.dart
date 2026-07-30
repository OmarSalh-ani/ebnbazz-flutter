import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/plan_level_api.dart';
import '../data/plan_level_repository.dart';
import '../models/plan_level_models.dart';

final planLevelApiProvider = Provider<PlanLevelApi>((ref) {
  return PlanLevelApi(ref.watch(apiClientProvider));
});

final planLevelRepositoryProvider = Provider<PlanLevelRepository>((ref) {
  return PlanLevelRepository(ref.watch(planLevelApiProvider));
});

final planLevelFormDataProvider =
    FutureProvider.autoDispose<PlanLevelFormData>((ref) {
  return ref.watch(planLevelRepositoryProvider).getFormData();
});

final planLevelsListProvider =
    FutureProvider.autoDispose<List<PlanLevelItem>>((ref) {
  return ref.watch(planLevelRepositoryProvider).getPlanLevels();
});

final readyPlansListProvider =
    FutureProvider.autoDispose<List<ReadyPlanItem>>((ref) {
  return ref.watch(planLevelRepositoryProvider).getReadyPlans();
});

final assignPlanFormDataProvider = FutureProvider.autoDispose
    .family<AssignPlanFormData, int?>((ref, studentId) {
  return ref
      .watch(planLevelRepositoryProvider)
      .getAssignFormData(studentId: studentId);
});
