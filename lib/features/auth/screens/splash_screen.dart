import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/models/app_role.dart';
import '../../../app/providers/app_role_provider.dart';
import '../../../core/services/permission_onboarding_service.dart';
import '../../../core/services/product_intro_service.dart';
import '../../../splash/splash_screen.dart' as premium;
import 'package:masged_parent_app/shared/router/app_routes.dart';
import '../../teacher/auth/providers/auth_providers.dart';
import '../providers/auth_provider.dart';

/// Auth-aware wrapper around the premium animated splash screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  var _navigationStarted = false;

  @override
  void initState() {
    super.initState();
    _prepareNavigation();
  }

  /// Runs auth initialization in parallel with the splash animation.
  Future<void> _prepareNavigation() async {
    await ref.read(authProvider.notifier).ensureInitialized();
  }

  Future<void> _navigateToNext() async {
    if (_navigationStarted || !mounted) return;
    _navigationStarted = true;

    final role = ref.read(appRoleProvider);
    final auth = ref.read(authProvider);

    final introComplete = await ProductIntroService.hasCompleted();
    if (!mounted) return;

    if (!introComplete) {
      context.go(AppRoutes.productIntro);
      return;
    }

    if (role == null) {
      context.go(AppRoutes.login);
      return;
    }

    final onboardingComplete =
        await PermissionOnboardingService.hasCompleted();
    if (!mounted) return;

    switch (role) {
      case AppRole.teacher:
        final teacherSession = ref.read(authControllerProvider).valueOrNull;
        if (teacherSession != null) {
          context.go(
            onboardingComplete
                ? AppRoutes.teacherDashboard
                : AppRoutes.permissionAsk,
          );
        } else {
          context.go(AppRoutes.login);
        }
      case AppRole.parent:
        if (auth.isAuthenticated) {
          context.go(
            onboardingComplete ? AppRoutes.home : AppRoutes.permissionAsk,
          );
        } else {
          context.go(AppRoutes.login);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return premium.SplashScreen(
      onComplete: _navigateToNext,
    );
  }
}
