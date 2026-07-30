import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class PermissionOnboardingService {
  PermissionOnboardingService._();

  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyPermissionsOnboardingComplete) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyPermissionsOnboardingComplete, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyPermissionsOnboardingComplete);
  }
}
