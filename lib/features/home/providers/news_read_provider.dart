import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/news_read_service.dart';
import 'news_provider.dart';

final newsReadServiceProvider = Provider((ref) => NewsReadService());

class NewsReadNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    return ref.read(newsReadServiceProvider).getReadIds();
  }

  Future<void> markAllAsRead(Iterable<String> ids) async {
    await ref.read(newsReadServiceProvider).markAllAsRead(ids);
    state = AsyncData(await ref.read(newsReadServiceProvider).getReadIds());
  }
}

final newsReadProvider =
    AsyncNotifierProvider<NewsReadNotifier, Set<String>>(NewsReadNotifier.new);

final hasUnreadNewsProvider = Provider<bool>((ref) {
  final readIds = ref.watch(newsReadProvider).valueOrNull ?? {};
  final newsAsync = ref.watch(newsProvider);

  return newsAsync.maybeWhen(
    data: (news) {
      if (news.isEmpty) return false;
      return ref
          .read(newsReadServiceProvider)
          .hasUnread(news.map((n) => n.id), readIds);
    },
    orElse: () => false,
  );
});
