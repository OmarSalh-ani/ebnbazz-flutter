import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class ProductIntroService {
  ProductIntroService._();

  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyProductIntroComplete) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyProductIntroComplete, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyProductIntroComplete);
  }
}
