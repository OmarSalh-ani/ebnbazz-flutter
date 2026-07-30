import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/adhkar_reminder_config.dart';
import '../models/adhkar_item.dart';

class AdhkarProgressService {
  AdhkarProgressService(this._prefs);

  final SharedPreferences _prefs;

  static String todayKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(d);
  }

  String _progressKey({
    required String dateKey,
    required String sessionKey,
    required int categoryId,
    required int itemId,
  }) {
    return 'adhkar_progress_${dateKey}_${sessionKey}_${categoryId}_$itemId';
  }

  int getProgress({
    required String sessionKey,
    required int categoryId,
    required int itemId,
    DateTime? date,
  }) {
    final key = _progressKey(
      dateKey: todayKey(date),
      sessionKey: sessionKey,
      categoryId: categoryId,
      itemId: itemId,
    );
    return _prefs.getInt(key) ?? 0;
  }

  Future<int> incrementProgress({
    required String sessionKey,
    required int categoryId,
    required int itemId,
    required int targetCount,
  }) async {
    final dateKey = todayKey();
    final key = _progressKey(
      dateKey: dateKey,
      sessionKey: sessionKey,
      categoryId: categoryId,
      itemId: itemId,
    );
    final current = _prefs.getInt(key) ?? 0;
    final next = (current + 1).clamp(0, targetCount);
    await _prefs.setInt(key, next);
    return next;
  }

  Future<int> markComplete({
    required String sessionKey,
    required int categoryId,
    required int itemId,
    required int targetCount,
  }) async {
    final dateKey = todayKey();
    final key = _progressKey(
      dateKey: dateKey,
      sessionKey: sessionKey,
      categoryId: categoryId,
      itemId: itemId,
    );
    await _prefs.setInt(key, targetCount);
    return targetCount;
  }

  bool isItemDone({
    required String sessionKey,
    required int categoryId,
    required AdhkarItem item,
    DateTime? date,
  }) {
    final progress = getProgress(
      sessionKey: sessionKey,
      categoryId: categoryId,
      itemId: item.id,
      date: date,
    );
    return progress >= item.count;
  }

  bool isSessionComplete({
    required String sessionKey,
    required int categoryId,
    required List<AdhkarItem> items,
    DateTime? date,
  }) {
    if (items.isEmpty) return true;
    for (final item in items) {
      if (!isItemDone(
        sessionKey: sessionKey,
        categoryId: categoryId,
        item: item,
        date: date,
      )) {
        return false;
      }
    }
    return true;
  }

  int completedCount({
    required String sessionKey,
    required int categoryId,
    required List<AdhkarItem> items,
    DateTime? date,
  }) {
    var done = 0;
    for (final item in items) {
      if (isItemDone(
        sessionKey: sessionKey,
        categoryId: categoryId,
        item: item,
        date: date,
      )) {
        done++;
      }
    }
    return done;
  }

  bool isMorningCompleteToday(List<AdhkarItem> items, [DateTime? date]) {
    return isSessionComplete(
      sessionKey: AdhkarReminderConfig.morningSessionKey,
      categoryId: AdhkarReminderConfig.morningCategoryId,
      items: items,
      date: date,
    );
  }

  bool isEveningCompleteToday(List<AdhkarItem> items, [DateTime? date]) {
    return isSessionComplete(
      sessionKey: AdhkarReminderConfig.eveningSessionKey,
      categoryId: AdhkarReminderConfig.morningCategoryId,
      items: items,
      date: date,
    );
  }

  Map<int, int> loadCategoryProgress({
    required String sessionKey,
    required int categoryId,
    required List<AdhkarItem> items,
    DateTime? date,
  }) {
    return {
      for (final item in items)
        item.id: getProgress(
          sessionKey: sessionKey,
          categoryId: categoryId,
          itemId: item.id,
          date: date,
        ),
    };
  }
}
