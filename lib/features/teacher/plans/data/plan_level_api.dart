import 'package:masged_parent_app/teacher_core/network/api_client.dart';

import '../models/plan_level_models.dart';

class PlanLevelApi {
  PlanLevelApi(this._client);

  final TeacherApiClient _client;

  Future<PlanLevelFormData> getFormData() {
    return _client.get<PlanLevelFormData>(
      '/api/planlevels/form-data',
      parseData: (json) =>
          PlanLevelFormData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<PlanLevelItem>> getPlanLevels() {
    return _client.get<List<PlanLevelItem>>(
      '/api/planlevels',
      parseData: (json) {
        final list = json as List<dynamic>;
        return list
            .map(
              (e) => PlanLevelItem.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      },
    );
  }

  Future<PlanLevelItem> createPlanLevel(SavePlanLevelRequest request) {
    return _client.post<PlanLevelItem>(
      '/api/planlevels',
      body: request.toJson(),
      parseData: (json) => PlanLevelItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<String> updatePlanLevel(int id, SavePlanLevelRequest request) {
    return _client.putCommand(
      '/api/planlevels/$id',
      body: request.toJson(),
    );
  }

  Future<String> deletePlanLevel(int id) {
    return _client.deleteCommand('/api/planlevels/$id');
  }

  Future<List<ReadyPlanItem>> getReadyPlans() {
    return _client.get<List<ReadyPlanItem>>(
      '/api/planlevels/ready-plans',
      parseData: (json) {
        final list = json as List<dynamic>;
        return list
            .map(
              (e) => ReadyPlanItem.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      },
    );
  }

  Future<ReadyPlanItem> createReadyPlan(SaveReadyPlanRequest request) {
    return _client.post<ReadyPlanItem>(
      '/api/planlevels/ready-plans',
      body: request.toJson(),
      parseData: (json) => ReadyPlanItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<String> updateReadyPlan(int id, SaveReadyPlanRequest request) {
    return _client.putCommand(
      '/api/planlevels/ready-plans/$id',
      body: request.toJson(),
    );
  }

  Future<String> deleteReadyPlan(int id) {
    return _client.deleteCommand('/api/planlevels/ready-plans/$id');
  }

  Future<AssignPlanFormData> getAssignFormData({int? studentId}) {
    return _client.get<AssignPlanFormData>(
      '/api/studentplans/assign-form',
      queryParameters:
          studentId != null ? {'studentId': studentId} : null,
      parseData: (json) =>
          AssignPlanFormData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<int> getCircleDaysCount({
    required String startDate,
    required String endDate,
  }) async {
    final result = await _client.get<Map<String, dynamic>>(
      '/api/studentplans/circle-days-count',
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
      },
      parseData: (json) => json as Map<String, dynamic>,
    );
    return result['count'] as int? ?? 0;
  }

  Future<String> assignPlan(AssignPlanRequest request) {
    return _client.postCommand(
      '/api/studentplans/assign',
      body: request.toJson(),
    );
  }
}
