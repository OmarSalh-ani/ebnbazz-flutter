import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import 'package:masged_parent_app/shared/utils/connectivity_guard.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.children)) return 1;
    if (location.startsWith(AppRoutes.attendance)) return 2;
    if (location.startsWith(AppRoutes.services)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    final route = switch (index) {
      0 => AppRoutes.home,
      1 => AppRoutes.children,
      2 => AppRoutes.attendance,
      3 => AppRoutes.services,
      4 => AppRoutes.profile,
      _ => AppRoutes.home,
    };

    ConnectivityGuard.tryNavigate(
      ref,
      () => context.go(route),
      context: context,
      route: route,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: AppConstants.navLabels[0],
                    isActive: currentIndex == 0,
                    onTap: () => _onTap(context, ref, 0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.child_care_outlined,
                    activeIcon: Icons.child_care_rounded,
                    label: AppConstants.navLabels[1],
                    isActive: currentIndex == 1,
                    onTap: () => _onTap(context, ref, 1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.fact_check_outlined,
                    activeIcon: Icons.fact_check_rounded,
                    label: AppConstants.navLabels[2],
                    isActive: currentIndex == 2,
                    onTap: () => _onTap(context, ref, 2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.grid_view_rounded,
                    activeIcon: Icons.grid_view_rounded,
                    label: AppConstants.navLabels[3],
                    isActive: currentIndex == 3,
                    onTap: () => _onTap(context, ref, 3),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: AppConstants.navLabels[4],
                    isActive: currentIndex == 4,
                    onTap: () => _onTap(context, ref, 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppFonts.cairo(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
