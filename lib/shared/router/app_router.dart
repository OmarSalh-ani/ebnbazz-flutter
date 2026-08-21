import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/models/app_role.dart';
import '../../app/providers/app_role_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/permission_onboarding_provider.dart';
import '../../features/auth/providers/registration_config_provider.dart';
import '../../features/onboarding/providers/product_intro_provider.dart';
import '../../features/auth/screens/permission_ask_page.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/onboarding/screens/product_intro_page.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/children/screens/children_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/children/screens/quran_screen.dart';
import '../../features/children/screens/child_profile_screen.dart';
import '../../features/children/models/child_model.dart';
import '../../features/chat/screens/chat_teachers_screen.dart';
import '../../features/chat/screens/chat_detail_screen.dart';
import '../../features/chat/models/chat_teacher_thread.dart';
import '../../features/ziker/screens/ziker_screen.dart';
import '../../features/ziker/screens/ziker_stats_screen.dart';
import '../../features/quran/quran_route.dart';
import '../../features/quran/screens/quran_main_screen.dart';
import '../../features/quran/screens/surah_detail_screen.dart';
import '../../features/home/models/news_model.dart';
import '../../features/home/screens/masged_news_screen.dart';
import '../../features/home/screens/news_details_screen.dart';
import '../../features/library/models/center_release_model.dart';
import '../../features/library/screens/library_pdf_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/adhkar/screens/adhkar_home_screen.dart';
import '../../features/adhkar/screens/adhkar_group_screen.dart';
import '../../features/adhkar/screens/adhkar_detail_screen.dart';
import '../../features/teacher/auth/providers/auth_providers.dart';
import '../../features/teacher/auth/models/auth_user.dart';
import '../../features/teacher/dashboard/screens/dashboard_screen.dart';
import 'package:masged_parent_app/shared/widgets/main_scaffold.dart';

import '../../features/children/screens/add_child_screen.dart';
import '../../features/home/screens/services_screen.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';

/// go_router may already decode path segments; decoding again throws when the
/// value contains a literal `%` or invalid percent sequences.
String _pathParameter(String? value, {String fallback = ''}) {
  final raw = (value == null || value.isEmpty) ? fallback : value;
  if (!raw.contains('%')) return raw;
  try {
    return Uri.decodeComponent(raw);
  } on ArgumentError {
    return raw;
  }
}

/// Shared mosque service routes reachable without parent shell auth.
const _publicServicePaths = [
  AppRoutes.services,
  AppRoutes.zikerStats,
  AppRoutes.holyQuran,
  AppRoutes.library,
  AppRoutes.masgedNews,
  AppRoutes.adhkar,
];

bool _isPublicServiceRoute(String location) {
  if (_publicServicePaths.any((p) => location.startsWith(p))) return true;
  if (location.startsWith(AppRoutes.ziker)) return true;
  if (location.startsWith(AppRoutes.surahDetail)) return true;
  if (location.startsWith(AppRoutes.newsDetails)) return true;
  if (location.startsWith(AppRoutes.libraryPdf)) return true;
  return false;
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Mosque services shared by parent and teacher — outside [ShellRoute]
/// so navigation from `/teacher/dashboard` does not enter [MainScaffold].
List<RouteBase> _sharedIslamicServiceRoutes() {
  return [
    GoRoute(
      path: AppRoutes.ziker,
      pageBuilder: (context, state) {
        final zikerName = _pathParameter(
          state.pathParameters['name'],
          fallback: 'سبحان الله',
        );
        return NoTransitionPage<void>(
          child: ZikerScreen(zikerName: zikerName),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.zikerStats,
      pageBuilder: (context, state) => const NoTransitionPage<void>(
        child: ZikerStatsScreen(),
      ),
    ),
    
    
    GoRoute(
      path: AppRoutes.holyQuran,
      pageBuilder: (context, state) => NoTransitionPage<void>(
        child: buildQuranScreen(const QuranMainScreen()),
      ),
    ),
    GoRoute(
      path: AppRoutes.library,
      pageBuilder: (context, state) => const NoTransitionPage<void>(
        child: LibraryScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.libraryPdf,
      pageBuilder: (context, state) {
        final release = state.extra as CenterReleaseModel;
        return NoTransitionPage<void>(
          child: LibraryPdfScreen(release: release),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.surahDetail,
      pageBuilder: (context, state) {
        final surahNumber =
            int.tryParse(state.pathParameters['surahNumber'] ?? '1') ?? 1;
        return NoTransitionPage<void>(
          child: buildQuranScreen(
            SurahDetailScreen(surahNumber: surahNumber),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.masgedNews,
      pageBuilder: (context, state) => const NoTransitionPage<void>(
        child: MasgedNewsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.newsDetails,
      pageBuilder: (context, state) {
        final news = state.extra as NewsModel;
        return NoTransitionPage<void>(
          child: NewsDetailsScreen(news: news),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adhkar,
      pageBuilder: (context, state) => const NoTransitionPage<void>(
        child: AdhkarHomeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adhkarGroup,
      pageBuilder: (context, state) {
        final groupId = state.pathParameters['groupId'] ?? '';
        return NoTransitionPage<void>(
          child: AdhkarGroupScreen(groupId: groupId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adhkarCategory,
      pageBuilder: (context, state) {
        final categoryId =
            int.tryParse(state.pathParameters['categoryId'] ?? '') ?? 0;
        final session = state.uri.queryParameters['session'] ??
            'cat_$categoryId';
        return NoTransitionPage<void>(
          child: AdhkarDetailScreen(
            categoryId: categoryId,
            session: session,
          ),
        );
      },
    ),
  ];
}

String _postPermissionDestination(AppRole? role) {
  return role == AppRole.teacher
      ? AppRoutes.teacherDashboard
      : AppRoutes.home;
}

/// Notifies [GoRouter] when auth or role changes.
final _routerRefreshProvider = Provider<RouterRefresh>((ref) {
  final refresh = RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return refresh;
});

class RouterRefresh extends ChangeNotifier {
  RouterRefresh(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    _ref.listen<AppRole?>(appRoleProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue<bool>>(
      permissionOnboardingProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<AsyncValue<bool>>(
      productIntroProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<AsyncValue<AuthUser?>>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerRefresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: routerRefresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final role = ref.read(appRoleProvider);
      final location = state.matchedLocation;
      final isAuth = authState.isAuthenticated;
      final isInitial = authState.status == AuthStatus.initial;
      final isSplash = location == AppRoutes.splash;
      final isLogin = location == AppRoutes.login;
      final isPermissionAsk = location == AppRoutes.permissionAsk;
      final teacherUser = ref.read(authControllerProvider).valueOrNull;
      final hasTeacherSession = teacherUser != null;

      if (isInitial && isSplash) return null;

      if (isSplash) {
        return null;
      }

      // Permissions are requested only at feature use (Guideline 5.1.1(iv)).
      // Legacy /permission-ask route immediately completes and redirects.
      if (isPermissionAsk) {
        return _postPermissionDestination(role);
      }

      if (isLogin) {
        if (role == AppRole.teacher) {
          if (hasTeacherSession) {
            return AppRoutes.teacherDashboard;
          }
        } else if (isAuth) {
          return AppRoutes.home;
        }
        return null;
      }

      // Teacher flow — separate from parent shell
      if (role == AppRole.teacher) {
        if (_isPublicServiceRoute(location) || location.startsWith(AppRoutes.ziker)) {
          return null;
        }
        if (!hasTeacherSession) {
          if (isLogin || isSplash || location == AppRoutes.register) {
            return null;
          }
          return AppRoutes.login;
        }
        if (location == AppRoutes.teacherDashboard ||
            location == AppRoutes.permissionAsk) {
          return null;
        }
        return AppRoutes.teacherDashboard;
      }

      final protectedBasePaths = [
        '/children',
        '/profile',
        '/schedule',
        '/attendance',
        '/notifications',
        '/chat-teachers',
        '/quran',
        '/child-profile',
        '/chat-detail',
      ];
      final isProtectedRoute =
          protectedBasePaths.any((p) => location.startsWith(p));

      if (!isAuth && isProtectedRoute) {
        return AppRoutes.login;
      }

      if (location == AppRoutes.register) {
        final registrationConfig =
            ref.read(registrationConfigProvider).valueOrNull;
        if (registrationConfig != null && !registrationConfig.registrationEnabled) {
          return AppRoutes.login;
        }
      }

      if (isAuth &&
          (location == AppRoutes.login ||
              location == AppRoutes.register)) {
        return AppRoutes.home;
      }

      if (location == AppRoutes.teacherDashboard) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.productIntro,
        builder: (context, state) => const ProductIntroPage(),
      ),
      GoRoute(
        path: AppRoutes.permissionAsk,
        builder: (context, state) => const PermissionAskPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final phone = _pathParameter(state.pathParameters['phone']);
          return OtpScreen(phone: phone);
        },
      ),
      ..._sharedIslamicServiceRoutes(),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.children,
            builder: (context, state) => const ChildrenScreen(),
          ),
          GoRoute(
            path: AppRoutes.schedule,
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: AppRoutes.attendance,
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.services,
            builder: (context, state) => const ServicesScreen(),
          ),
          GoRoute(
            path: AppRoutes.addChild,
            builder: (context, state) => const AddChildScreen(),
          ),
          GoRoute(
            path: AppRoutes.quran,
            builder: (context, state) {
              final child = state.extra as ChildModel;
              return buildQuranScreen(
                QuranScreen(child: child),
                appBarTitle: 'تسميع القرآن',
                headline: 'متابعة التسميع متاحة على تطبيق الجوال',
                description:
                    'عرض خطة الحفظ والمراجعة من المعلم، مع قراءة الآيات، '
                    'متاح في تطبيق الجوال فقط.',
              );
            },
          ),
          GoRoute(
            path: AppRoutes.childProfile,
            builder: (context, state) {
              final child = state.extra as ChildModel;
              return ChildProfileScreen(child: child);
            },
          ),
          GoRoute(
            path: AppRoutes.chatTeachers,
            builder: (context, state) => const ChatTeachersScreen(),
          ),
          GoRoute(
            path: AppRoutes.chatDetail,
            builder: (context, state) {
              final thread = state.extra as ChatTeacherThread;
              return ChatDetailScreen(thread: thread);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
