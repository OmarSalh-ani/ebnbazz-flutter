import '../models/student_plan_models.dart';
import 'student_plan_api.dart';

class StudentPlanRepository {
  StudentPlanRepository(this._api);

  final StudentPlanApi _api;

  Future<PlanFormData> getFormData() => _api.getFormData();

  Future<List<int>> getAyahNumbers(int surahId) => _api.getAyahNumbers(surahId);

  Future<StudentPlanOverview> getOverview(int studentId) =>
      _api.getOverview(studentId);

  Future<StudentPlanDetail> getPlanDetail(int studentId, int planId) =>
      _api.getPlanDetail(studentId, planId);

  Future<int> createPlan(
    int studentId,
    List<PlanRowInput> rows, {
    DateTime? planStartDate,
    DateTime? planEndDate,
  }) =>
      _api.createPlan(
        studentId,
        rows,
        planStartDate: planStartDate,
        planEndDate: planEndDate,
      );

  Future<String> addPlanRows(
    int studentId,
    int planId,
    List<PlanRowInput> rows, {
    DateTime? planStartDate,
    DateTime? planEndDate,
  }) =>
      _api.addPlanRows(
        studentId,
        planId,
        rows,
        planStartDate: planStartDate,
        planEndDate: planEndDate,
      );

  Future<String> updatePlanDates(
    int studentId,
    int planId, {
    required DateTime planStartDate,
    required DateTime planEndDate,
  }) =>
      _api.updatePlanDates(
        studentId,
        planId,
        planStartDate: planStartDate,
        planEndDate: planEndDate,
      );

  Future<String> closeExpiredPlan(int studentId, int planId) =>
      _api.closeExpiredPlan(studentId, planId);

  Future<String> logRowStatus({
    required int studentId,
    required String rowKey,
    required String status,
    required String tabType,
    int? confirmedToAyahNumber,
  }) =>
      _api.logRowStatus(
        studentId: studentId,
        rowKey: rowKey,
        status: status,
        tabType: tabType,
        confirmedToAyahNumber: confirmedToAyahNumber,
      );

  Future<String> deleteRow({
    required int studentId,
    required String rowKey,
  }) =>
      _api.deleteRow(studentId: studentId, rowKey: rowKey);

  Future<String> updateRow({
    required int studentId,
    required String rowKey,
    required int surahId,
    required int fromAyahNumber,
    required int toAyahNumber,
    required String planType,
    String? surahName,
  }) =>
      _api.updateRow(
        studentId: studentId,
        rowKey: rowKey,
        surahId: surahId,
        fromAyahNumber: fromAyahNumber,
        toAyahNumber: toAyahNumber,
        planType: planType,
        surahName: surahName,
      );

  Future<BulkAssignPlanResponse> bulkAssignPlans(BulkAssignPlanRequest request) =>
      _api.bulkAssignPlans(request);

  Future<List<ExpandedPlanRowPreview>> expandRows({
    String planType = 'حفظ',
    SurahRangeSelection? range,
    List<PlanRowInput> rows = const [],
  }) =>
      _api.expandRows(planType: planType, range: range, rows: rows);
}
