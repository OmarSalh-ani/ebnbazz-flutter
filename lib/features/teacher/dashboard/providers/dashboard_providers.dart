import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/dashboard_repository.dart';
import '../data/home_api.dart';
import '../models/dashboard_models.dart';

final homeApiProvider = Provider<HomeApi>((ref) {
  return HomeApi(ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(homeApiProvider));
});

final dashboardPageProvider =
    AsyncNotifierProvider<DashboardPageController, DashboardPageData>(
  DashboardPageController.new,
);

class DashboardPageController extends AsyncNotifier<DashboardPageData> {
  String _search = '';

  String get search => _search;

  @override
  Future<DashboardPageData> build() async {
    ref.watch(
      authControllerProvider.select((state) => state.valueOrNull?.id),
    );
    return _load();
  }

  Future<void> searchStudents(String term) async {
    final trimmed = term.trim();
    if (trimmed == _search) return;

    _search = trimmed;
    state = AsyncValue<DashboardPageData>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(_load);
  }

  Future<void> refresh() async {
    state = AsyncValue<DashboardPageData>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(_load);
  }

  Future<DashboardPageData> _load() {
    return ref.read(dashboardRepositoryProvider).loadPage(
          search: _search.isEmpty ? null : _search,
        );
  }
}
