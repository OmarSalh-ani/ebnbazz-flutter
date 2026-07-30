import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/push_notification_service.dart';
import '../config/adhkar_reminder_config.dart';
import '../providers/adhkar_progress_provider.dart';
import '../providers/adhkar_provider.dart';
import 'adhkar_progress_service.dart';

class AdhkarNotificationService {
  AdhkarNotificationService(this._ref, this._push, this._progress);

  final Ref _ref;
  final PushNotificationService _push;
  final AdhkarProgressService _progress;

  Future<void> sync() async {
    if (kIsWeb) return;

    try {
      final morningCategory = await _ref.read(
        adhkarCategoryProvider(AdhkarReminderConfig.morningCategoryId).future,
      );

      await _push.syncAdhkarReminders(
        morningComplete:
            _progress.isMorningCompleteToday(morningCategory.items),
        eveningComplete:
            _progress.isEveningCompleteToday(morningCategory.items),
      );
    } catch (e, st) {
      debugPrint('Adhkar notification sync failed: $e\n$st');
    }
  }
}

final adhkarNotificationServiceProvider =
    Provider<AdhkarNotificationService>((ref) {
  return AdhkarNotificationService(
    ref,
    ref.watch(pushNotificationServiceProvider),
    ref.watch(adhkarProgressServiceProvider),
  );
});

final adhkarNotificationBootstrapProvider = Provider<void>((ref) {
  if (kIsWeb) return;
  unawaited(ref.read(adhkarNotificationServiceProvider).sync());
});
