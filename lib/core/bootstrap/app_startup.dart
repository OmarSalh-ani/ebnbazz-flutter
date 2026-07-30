import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../features/quran/helpers/hive_helper.dart';
import '../../features/quran/helpers/initializeData.dart';

/// Runs non-critical startup work after [runApp] on web so the first frame
/// is not blocked by locale data.
/// Quran Hive settings are mobile-only (reader is disabled on web).
Future<void> runDeferredWebStartup() async {
  unawaited(initializeDateFormatting('ar', null));
}

Future<void> configureWebPlatform() async {
  GoogleFonts.config.allowRuntimeFetching = false;
}

Future<void> runMobileStartup() async {
  try {
    // Bundled Cairo in pubspec — avoid runtime font downloads (Play Data Safety).
    GoogleFonts.config.allowRuntimeFetching = false;
    await Hive.initFlutter();
    await initializeHive();
    await initHiveValues();
    await initializeDateFormatting('ar', null);
  } catch (_) {
    // Startup optimizations are best-effort; the app must still launch.
  }
}
