import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/providers/app_role_provider.dart';
import 'core/bootstrap/app_startup.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'shared/router/app_router.dart';
import 'core/network/connectivity_provider.dart';
import 'core/services/product_intro_service.dart';
import 'core/services/push_notification_service.dart';
import 'features/video_call/utils/parent_video_call_launcher.dart';
import 'features/chat/utils/chat_notification_launcher.dart';
import 'features/adhkar/utils/adhkar_notification_launcher.dart';
import 'features/adhkar/services/adhkar_notification_service.dart';
import 'features/adhkar/services/adhkar_progress_service.dart';
import 'features/teacher/session/teacher_session_cache.dart';
import 'shared/widgets/app_upgrade_wrapper.dart';
import 'shared/widgets/foreground_push_banner.dart';
import 'shared/widgets/offline_banner.dart';

import 'dart:ui' as ui;
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await configureWebPlatform();
  }

  final prefs = await SharedPreferences.getInstance();

  if (kDebugMode &&
      const bool.fromEnvironment('FORCE_ONBOARDING', defaultValue: true)) {
    await ProductIntroService.reset();
  }

  usePathUrlStrategy();

  if (kIsWeb) {
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MasgedUnifiedApp(),
      ),
    );
    unawaited(runDeferredWebStartup());
    return;
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MasgedUnifiedApp(),
    ),
  );
  unawaited(runMobileStartup());
}

class MasgedUnifiedApp extends ConsumerStatefulWidget {
  const MasgedUnifiedApp({super.key});

  @override
  ConsumerState<MasgedUnifiedApp> createState() => _MasgedUnifiedAppState();
}

class _MasgedUnifiedAppState extends ConsumerState<MasgedUnifiedApp>
    with WidgetsBindingObserver {
  var _pushConfigured = false;
  String? _lastAdhkarSyncDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _ensurePushConfigured() {
    if (_pushConfigured || kIsWeb) return;
    _pushConfigured = true;
    unawaited(
      ref.read(pushNotificationServiceProvider).initialize(
            ref,
            onMeetingOpened: (meetingId) {
              unawaited(openParentVideoCallFromMeeting(ref, meetingId));
            },
            onChatOpened: (target) {
              unawaited(openChatFromPushNotification(ref, target));
            },
            onAdhkarOpened: (groupId) {
              unawaited(openAdhkarFromPushNotification(ref, groupId));
            },
          ),
    );
  }

  Future<void> _syncAdhkarNotifications() async {
    if (kIsWeb) return;
    await ref.read(adhkarNotificationServiceProvider).sync();
    _lastAdhkarSyncDate = AdhkarProgressService.todayKey();
  }

  void _syncAdhkarOnResume() {
    if (kIsWeb) return;
    final today = AdhkarProgressService.todayKey();
    if (_lastAdhkarSyncDate != today) {
      unawaited(_syncAdhkarNotifications());
      return;
    }
    unawaited(ref.read(adhkarNotificationServiceProvider).sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!kIsWeb) {
        unawaited(ref.read(pushNotificationServiceProvider).syncRegistration());
        _syncAdhkarOnResume();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(teacherSessionCacheBootstrapProvider);
    if (!kIsWeb) {
      ref.watch(pushNotificationBootstrapProvider);
      ref.watch(adhkarNotificationBootstrapProvider);
    }
    _ensurePushConfigured();
    final router = ref.watch(appRouterProvider);
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: router,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: AppUpgradeWrapper(
                child: _AppRootOverlay(
                  navigatorChild: child,
                  onMeetingTap: (meetingId) {
                    unawaited(
                      openParentVideoCallFromMeeting(ref, meetingId),
                    );
                  },
                  onChatTap: (target) {
                    unawaited(openChatFromPushNotification(ref, target));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Global overlays above the router navigator — isolated so connectivity and
/// push-banner rebuilds do not recreate [MaterialApp.router] navigator keys.
class _AppRootOverlay extends ConsumerWidget {
  const _AppRootOverlay({
    required this.navigatorChild,
    required this.onMeetingTap,
    required this.onChatTap,
  });

  final Widget? navigatorChild;
  final void Function(int meetingId) onMeetingTap;
  final void Function(ChatPushTarget target) onChatTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final child = navigatorChild;
    if (child == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: child),
        ForegroundPushBanner(
          onMeetingTap: onMeetingTap,
          onChatTap: onChatTap,
        ),
        if (!isOnline)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OfflineBanner(),
          ),
      ],
    );
  }
}
