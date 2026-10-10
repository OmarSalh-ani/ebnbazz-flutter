import '../models/plan_level_models.dart';
import 'plan_level_api.dart';

class PlanLevelRepository {
  PlanLevelRepository(this._api);

  final PlanLevelApi _api;

  Future<PlanLevelFormData> getFormData() => _api.getFormData();

  Future<List<PlanLevelItem>> getPlanLevels() => _api.getPlanLevels();

  Future<PlanLevelItem> createPlanLevel(SavePlanLevelRequest request) =>
      _api.createPlanLevel(request);

  Future<String> updatePlanLevel(int id, SavePlanLevelRequest request) =>
      _api.updatePlanLevel(id, request);

  Future<String> deletePlanLevel(int id) => _api.deletePlanLevel(id);

  Future<List<ReadyPlanItem>> getReadyPlans() => _api.getReadyPlans();

  Future<ReadyPlanItem> createReadyPlan(SaveReadyPlanRequest request) =>
      _api.createReadyPlan(request);

  Future<String> updateReadyPlan(int id, SaveReadyPlanRequest request) =>
      _api.updateReadyPlan(id, request);

  Future<String> deleteReadyPlan(int id) => _api.deleteReadyPlan(id);

  Future<AssignPlanFormData> getAssignFormData({int? studentId}) =>
      _api.getAssignFormData(studentId: studentId);

  Future<int> getCircleDaysCount({
    required String startDate,
    required String endDate,
  }) =>
      _api.getCircleDaysCount(startDate: startDate, endDate: endDate);

  Future<String> assignPlan(AssignPlanRequest request) =>
      _api.assignPlan(request);
}
