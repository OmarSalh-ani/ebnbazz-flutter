import '../models/dashboard_models.dart';
import 'home_api.dart';

class DashboardRepository {
  DashboardRepository(this._api);

  final HomeApi _api;

  Future<DashboardPageData> loadPage({String? search}) =>
      _api.getHome(search: search);
}
