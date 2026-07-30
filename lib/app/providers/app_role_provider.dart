import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_role.dart';

const _roleKey = 'masged_selected_app_role';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('Override sharedPreferencesProvider in main()');
});

final appRoleProvider =
    StateNotifierProvider<AppRoleNotifier, AppRole?>((ref) {
  return AppRoleNotifier(ref.watch(sharedPreferencesProvider));
});

class AppRoleNotifier extends StateNotifier<AppRole?> {
  AppRoleNotifier(this._prefs) : super(null) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    state = AppRoleStorage.fromStorage(_prefs.getString(_roleKey));
  }

  Future<void> selectRole(AppRole role) async {
    await _prefs.setString(_roleKey, role.storageKey);
    state = role;
  }

  Future<void> clearRole() async {
    await _prefs.remove(_roleKey);
    state = null;
  }
}
