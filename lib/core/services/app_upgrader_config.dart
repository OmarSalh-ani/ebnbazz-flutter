import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:upgrader/upgrader.dart';

Upgrader createAppUpgrader() {
  return Upgrader(
    countryCode: 'KW',
    languageCode: 'ar',
    messages: UpgraderMessages(code: 'ar'),
    durationUntilAlertAgain: const Duration(days: 1),
    debugLogging: kDebugMode,
  );
}
