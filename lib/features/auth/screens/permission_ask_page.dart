import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/models/app_role.dart';
import '../../../app/providers/app_role_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/router/app_routes.dart';
import '../providers/permission_onboarding_provider.dart';

/// Legacy route kept for deep links / old installs.
///
/// Apple Guideline 5.1.1(iv): do not show a custom permission wall that can
/// delay the system permission dialog. Permissions are requested only when a
/// feature needs them (video call, attendance, voice commands).
class PermissionAskPage extends ConsumerStatefulWidget {
  const PermissionAskPage({super.key});

  @override
  ConsumerState<PermissionAskPage> createState() => _PermissionAskPageState();
}

class _PermissionAskPageState extends ConsumerState<PermissionAskPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _completeAndLeave());
  }

  Future<void> _completeAndLeave() async {
    await ref.read(permissionOnboardingProvider.notifier).markCompleted();
    if (!mounted) return;
    final role = ref.read(appRoleProvider);
    context.go(
      role == AppRole.teacher ? AppRoutes.teacherDashboard : AppRoutes.home,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
