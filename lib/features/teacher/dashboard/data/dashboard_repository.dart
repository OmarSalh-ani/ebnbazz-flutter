import '../models/dashboard_models.dart';
import 'home_api.dart';

class DashboardRepository {
  DashboardRepository(this._api);

  final HomeApi _api;

  Future<DashboardPageData> loadPage({String? search, bool isMrkz = false}) =>
      _api.getHome(search: search, isMrkz: isMrkz);
}
