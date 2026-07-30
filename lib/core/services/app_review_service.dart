import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class AppReviewService {
  AppReviewService._();

  static final InAppReview _inAppReview = InAppReview.instance;

  static Future<void> recordLaunch() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(AppConstants.keyAppLaunchCount) ?? 0;
    await prefs.setInt(AppConstants.keyAppLaunchCount, count + 1);
  }

  static Future<void> maybePrompt() async {
    if (kIsWeb || kDebugMode) return;

    final prefs = await SharedPreferences.getInstance();
    final launchCount = prefs.getInt(AppConstants.keyAppLaunchCount) ?? 0;
    if (launchCount < AppConstants.reviewPromptMinLaunches) return;

    final promptCount = prefs.getInt(AppConstants.keyReviewPromptCount) ?? 0;
    if (promptCount >= AppConstants.reviewPromptMaxCount) return;

    final lastPromptAt = prefs.getString(AppConstants.keyLastReviewPromptAt);
    if (lastPromptAt != null) {
      final lastPrompt = DateTime.tryParse(lastPromptAt);
      if (lastPrompt != null) {
        final cooldown = Duration(days: AppConstants.reviewPromptCooldownDays);
        if (DateTime.now().difference(lastPrompt) < cooldown) return;
      }
    }

    if (!await _inAppReview.isAvailable()) return;

    await _inAppReview.requestReview();
    await prefs.setString(
      AppConstants.keyLastReviewPromptAt,
      DateTime.now().toIso8601String(),
    );
    await prefs.setInt(AppConstants.keyReviewPromptCount, promptCount + 1);
  }

  static Future<void> promptNow() async {
    if (kIsWeb) return;

    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
      return;
    }

    await _inAppReview.openStoreListing(
      appStoreId: AppConstants.appStoreId,
    );
  }
}
