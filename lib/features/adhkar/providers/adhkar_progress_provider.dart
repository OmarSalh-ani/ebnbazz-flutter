import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_role_provider.dart';
import '../config/adhkar_reminder_config.dart';
import '../models/adhkar_item.dart';
import '../services/adhkar_notification_service.dart';
import '../services/adhkar_progress_service.dart';
import 'adhkar_provider.dart';

final adhkarProgressServiceProvider = Provider<AdhkarProgressService>((ref) {
  return AdhkarProgressService(ref.watch(sharedPreferencesProvider));
});

/// Ticks every minute so home reminders react to time windows.
final adhkarClockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  ).startWith(DateTime.now());
});

class AdhkarCategoryProgressArgs {
  const AdhkarCategoryProgressArgs({
    required this.sessionKey,
    required this.categoryId,
  });

  final String sessionKey;
  final int categoryId;

  @override
  bool operator ==(Object other) {
    return other is AdhkarCategoryProgressArgs &&
        other.sessionKey == sessionKey &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(sessionKey, categoryId);
}

class AdhkarCategoryProgressNotifier
    extends StateNotifier<Map<int, int>> {
  AdhkarCategoryProgressNotifier(
    this.ref,
    this.args,
  ) : super({}) {
    reload();
  }

  final Ref ref;
  final AdhkarCategoryProgressArgs args;

  List<AdhkarItem> get _items {
    final category =
        ref.read(adhkarCategoryProvider(args.categoryId)).valueOrNull;
    return category?.items ?? const [];
  }

  void reload() {
    final service = ref.read(adhkarProgressServiceProvider);
    state = service.loadCategoryProgress(
      sessionKey: args.sessionKey,
      categoryId: args.categoryId,
      items: _items,
    );
  }

  Future<void> recordTap(AdhkarItem item) async {
    final service = ref.read(adhkarProgressServiceProvider);
    final current = state[item.id] ?? 0;
    if (current >= item.count) return;

    final next = item.count == 1
        ? await service.markComplete(
            sessionKey: args.sessionKey,
            categoryId: args.categoryId,
            itemId: item.id,
            targetCount: item.count,
          )
        : await service.incrementProgress(
            sessionKey: args.sessionKey,
            categoryId: args.categoryId,
            itemId: item.id,
            targetCount: item.count,
          );

    state = {...state, item.id: next};
    ref.invalidate(adhkarReminderProvider);
    await ref.read(adhkarNotificationServiceProvider).sync();
  }

  int get completedCount {
    var done = 0;
    for (final item in _items) {
      if ((state[item.id] ?? 0) >= item.count) done++;
    }
    return done;
  }

  int get totalCount => _items.length;
}

final adhkarCategoryProgressProvider = StateNotifierProvider.autoDispose
    .family<AdhkarCategoryProgressNotifier, Map<int, int>,
        AdhkarCategoryProgressArgs>((ref, args) {
  final notifier = AdhkarCategoryProgressNotifier(ref, args);
  ref.listen(adhkarCategoryProvider(args.categoryId), (previous, next) {
    next.whenData((_) => notifier.reload());
  });
  return notifier;
});

class AdhkarReminderState {
  const AdhkarReminderState({
    required this.showMorning,
    required this.showEvening,
    required this.morningComplete,
    required this.eveningComplete,
  });

  final bool showMorning;
  final bool showEvening;
  final bool morningComplete;
  final bool eveningComplete;
}

final adhkarReminderProvider = Provider<AdhkarReminderState>((ref) {
  ref.watch(adhkarClockProvider);
  final morningCategory = ref
      .watch(adhkarCategoryProvider(AdhkarReminderConfig.morningCategoryId))
      .valueOrNull;
  final items = morningCategory?.items ?? const [];

  final service = ref.read(adhkarProgressServiceProvider);
  final now = DateTime.now();

  final morningComplete = service.isMorningCompleteToday(items, now);
  final eveningComplete = service.isEveningCompleteToday(items, now);

  final showMorning = !morningComplete &&
      now.hour >= AdhkarReminderConfig.morningWindowStartHour &&
      now.hour < AdhkarReminderConfig.morningWindowEndHour;

  final showEvening = !eveningComplete &&
      now.hour >= AdhkarReminderConfig.eveningWindowStartHour &&
      now.hour < AdhkarReminderConfig.eveningWindowEndHour;

  return AdhkarReminderState(
    showMorning: showMorning,
    showEvening: showEvening,
    morningComplete: morningComplete,
    eveningComplete: eveningComplete,
  );
});

extension _StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
