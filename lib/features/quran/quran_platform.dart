import 'package:flutter/foundation.dart' show kIsWeb;

/// Full Quran reader (604 page fonts, Hive settings) runs on mobile only.
/// Web shows [QuranMobileOnlyScreen] instead.
bool get isQuranReaderSupported => !kIsWeb;
