import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connectivity_provider.dart';
import '../../core/theme/app_colors.dart';
import '../router/app_routes.dart';

class ConnectivityGuard {
  ConnectivityGuard._();

  static bool requiresInternet(String route) {
    return !AppRoutes.isOfflineAllowed(route);
  }

  static bool tryNavigate(
    WidgetRef ref,
    VoidCallback navigate, {
    required BuildContext context,
    required String route,
  }) {
    final isOnline = ref.read(isOnlineProvider);
    if (isOnline || AppRoutes.isOfflineAllowed(route)) {
      navigate();
      return true;
    }

    _showOfflineMessage(context);
    return false;
  }

  static void _showOfflineMessage(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'لا يوجد اتصال بالإنترنت',
          style: AppFonts.cairo(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
