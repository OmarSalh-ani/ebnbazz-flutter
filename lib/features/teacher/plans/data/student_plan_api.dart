import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import '../models/student_plan_models.dart';

class StudentPlanApi {
  StudentPlanApi(this._client);

  final TeacherApiClient _client;

  Future<PlanFormData> getFormData() {
    return _client.get<PlanFormData>(
      '/api/studentplan2/form-data',
      parseData: (json) => PlanFormData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<int>> getAyahNumbers(int surahId) async {
    final ayahs = await _client.get<List<dynamic>>(
      '/api/studentplan2/surahs/$surahId/ayahs',
      parseData: (json) => json as List<dynamic>,
    );
    return ayahs
        .map((e) => (e as Map<String, dynamic>)['ayahNumber'] as int)
        .toList();
  }

  Future<StudentPlanOverview> getOverview(int studentId) {
    return _client.get<StudentPlanOverview>(
      '/api/studentplan2/$studentId',
      parseData: (json) =>
          StudentPlanOverview.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<StudentPlanDetail> getPlanDetail(int studentId, int planId) {
    return _client.get<StudentPlanDetail>(
      '/api/studentplan2/$studentId/plans/$planId',
      parseData: (json) =>
          StudentPlanDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<int> createPlan(
    int studentId,
    List<PlanRowInput> rows, {
    DateTime? planStartDate,
    DateTime? planEndDate,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/api/studentplan2/$studentId/plans',
      body: {
        'rows': rows.map((r) => r.toJson()).toList(),
        if (planStartDate != null)
          'planStartDate': _formatDate(planStartDate),
        if (planEndDate != null) 'planEndDate': _formatDate(planEndDate),
      },
      parseData: (json) => json as Map<String, dynamic>,
    );
    return result['planId'] as int;
  }

  Future<String> addPlanRows(
    int studentId,
    int planId,
    List<PlanRowInput> rows, {
    DateTime? planStartDate,
    DateTime? planEndDate,
  }) {
    return _client.postCommand(
      '/api/studentplan2/$studentId/plans/$planId/rows',
      body: {
        'rows': rows.map((r) => r.toJson()).toList(),
        if (planStartDate != null)
          'planStartDate': _formatDate(planStartDate),
        if (planEndDate != null) 'planEndDate': _formatDate(planEndDate),
      },
    );
  }

  Future<String> updatePlanDates(
    int studentId,
    int planId, {
    required DateTime planStartDate,
    required DateTime planEndDate,
  }) {
    return _client.putCommand(
      '/api/studentplan2/$studentId/plans/$planId/dates',
      body: {
        'planStartDate': _formatDate(planStartDate),
        'planEndDate': _formatDate(planEndDate),
      },
    );
  }

  Future<String> closeExpiredPlan(int studentId, int planId) {
    return _client.postCommand(
      '/api/studentplan2/$studentId/plans/$planId/close-expired',
    );
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<String> logRowStatus({
    required int studentId,
    required String rowKey,
    required String status,
    required String tabType,
    int? confirmedToAyahNumber,
  }) {
    return _client.postCommand(
      '/api/studentplan2/$studentId/log-status',
      body: {
        'rowKey': rowKey,
        'status': status,
        'tabType': tabType,
        if (confirmedToAyahNumber != null)
          'confirmedToAyahNumber': confirmedToAyahNumber,
      },
    );
  }

  Future<String> deleteRow({
    required int studentId,
    required String rowKey,
  }) {
    return _client.deleteCommand(
      '/api/studentplan2/rows/$rowKey?studentId=$studentId',
    );
  }

  Future<String> updateRow({
    required int studentId,
    required String rowKey,
    required int surahId,
    required int fromAyahNumber,
    required int toAyahNumber,
    required String planType,
    String? surahName,
  }) {
    return _client.putCommand(
      '/api/studentplan2/rows/$rowKey?studentId=$studentId',
      body: {
        'surahId': surahId,
        'fromAyahNumber': fromAyahNumber,
        'toAyahNumber': toAyahNumber,
        'planType': planType,
        if (surahName != null && surahName.trim().isNotEmpty)
          'surahName': surahName.trim(),
      },
    );
  }

  Future<BulkAssignPlanResponse> bulkAssignPlans(BulkAssignPlanRequest request) {
    return _client.post<BulkAssignPlanResponse>(
      '/api/studentplan2/bulk-plans',
      body: request.toJson(),
      parseData: (json) =>
          BulkAssignPlanResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<ExpandedPlanRowPreview>> expandRows({
    String planType = 'حفظ',
    SurahRangeSelection? range,
    List<PlanRowInput> rows = const [],
  }) {
    return _client.post<List<ExpandedPlanRowPreview>>(
      '/api/studentplan2/expand-rows',
      body: {
        'planType': planType,
        if (range != null) 'range': range.toJson(),
        'rows': rows.map((r) => r.toJson()).toList(),
      },
      parseData: (json) {
        final list = json as List<dynamic>;
        return list
            .map(
              (e) => ExpandedPlanRowPreview.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();
      },
    );
  }
}
