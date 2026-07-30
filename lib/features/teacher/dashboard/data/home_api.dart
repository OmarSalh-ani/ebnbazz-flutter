import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import '../models/dashboard_models.dart';

class HomeApi {
  HomeApi(this._client);

  final TeacherApiClient _client;

  Future<DashboardPageData> getHome({String? search}) {
    final trimmed = search?.trim();
    return _client.get<DashboardPageData>(
      '/api/home',
      queryParameters:
          trimmed != null && trimmed.isNotEmpty ? {'search': trimmed} : null,
      parseData: (json) => DashboardPageData.fromJson(json as Map<String, dynamic>),
    );
  }
}
