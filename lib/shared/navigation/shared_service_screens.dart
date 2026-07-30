import 'package:flutter/material.dart';

import '../../features/home/screens/masged_news_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/quran/quran_route.dart';
import '../../features/quran/screens/quran_main_screen.dart';
import '../../features/ziker/screens/ziker_stats_screen.dart';
import '../../features/adhkar/screens/adhkar_home_screen.dart';
import '../router/app_routes.dart';

/// Full-screen mosque service for a shared [AppRoutes] path.
Widget? sharedServiceScreenForRoute(String route, {bool teacherMode = false}) {
  switch (route) {
    case AppRoutes.zikerStats:
      return ZikerStatsScreen(useNavigatorPush: teacherMode);
    case AppRoutes.holyQuran:
      return buildQuranScreen(const QuranMainScreen());
    case AppRoutes.library:
      return const LibraryScreen();
    case AppRoutes.masgedNews:
      return const MasgedNewsScreen();
    case AppRoutes.adhkar:
      return const AdhkarHomeScreen();
    default:
      return null;
  }
}

void pushSharedService(BuildContext context, String route) {
  final screen = sharedServiceScreenForRoute(route, teacherMode: true);
  if (screen == null) {
    throw ArgumentError.value(route, 'route', 'Not a shared service route');
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => screen),
  );
}
