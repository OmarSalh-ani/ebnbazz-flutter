import 'package:flutter/widgets.dart';

import 'quran_platform.dart';
import 'screens/quran_mobile_only_screen.dart';

/// Returns [mobileScreen] on iOS/Android, or a polite mobile-only placeholder on web.
Widget buildQuranScreen(
  Widget mobileScreen, {
  String? appBarTitle,
  String? headline,
  String? description,
}) {
  if (isQuranReaderSupported) return mobileScreen;
  return QuranMobileOnlyScreen(
    appBarTitle: appBarTitle ?? 'القرآن الكريم',
    headline: headline ?? 'المصحف متاح على تطبيق الجوال',
    description: description,
  );
}
