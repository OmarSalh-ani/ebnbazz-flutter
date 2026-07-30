import 'package:shared_preferences/shared_preferences.dart';

class NewsReadService {
  static const _readIdsKey = 'read_masged_news_ids';

  Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readIdsKey) ?? []).toSet();
  }

  Future<void> markAllAsRead(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await getReadIds();
    current.addAll(ids);
    await prefs.setStringList(_readIdsKey, current.toList());
  }

  bool hasUnread(Iterable<String> newsIds, Set<String> readIds) {
    return newsIds.any((id) => id.isNotEmpty && !readIds.contains(id));
  }
}
