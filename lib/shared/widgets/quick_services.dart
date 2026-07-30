import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masged_parent_app/app/models/app_role.dart';
import 'package:masged_parent_app/app/providers/app_role_provider.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/features/quran/quran_platform.dart';
import 'package:masged_parent_app/shared/navigation/shared_service_screens.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import 'package:masged_parent_app/shared/utils/connectivity_guard.dart';

/// Metadata for shortcuts to shared mosque services (zikr, prayer, quran, etc.).
class QuickServiceItem {
  const QuickServiceItem({
    required this.label,
    required this.icon,
    required this.route,
    this.accentColor = AppColors.primary,
    this.showUnreadBadge = false,
  });

  final String label;
  final IconData icon;
  /// [AppRoutes] path for [GoRouter].
  final String route;
  final Color accentColor;
  final bool showUnreadBadge;

  static List<QuickServiceItem> _platformFiltered(
    List<QuickServiceItem> items,
  ) {
    if (isQuranReaderSupported) return items;
    return items
        .where((item) => item.route != AppRoutes.holyQuran)
        .toList();
  }

  /// Default order: mosque news first (parent home parity), then the rest.
  static List<QuickServiceItem> islamicShortcuts({
    bool unreadNewsBadge = false,
    bool newsFirst = true,
  }) {
    final news = QuickServiceItem(
      label: 'أخبار المسجد',
      icon: Icons.newspaper_rounded,
      route: AppRoutes.masgedNews,
      showUnreadBadge: unreadNewsBadge,
    );
    final core = [
      const QuickServiceItem(
        label: 'الأذكار',
        icon: Icons.auto_stories_rounded,
        route: AppRoutes.adhkar,
      ),
      
      const QuickServiceItem(
        label: 'القرآن الكريم',
        icon: Icons.menu_book_rounded,
        route: AppRoutes.holyQuran,
      ),
      const QuickServiceItem(
        label: 'المكتبة',
        icon: Icons.local_library_rounded,
        route: AppRoutes.library,
      ),
    ];
    final ordered =
        newsFirst ? <QuickServiceItem>[news, ...core] : [...core, news];

    return _platformFiltered(ordered);
  }

  /// Legacy `/services` grid — five tiles, no mosque news.
  static List<QuickServiceItem> servicesTabGridItems() {
    return _platformFiltered(const [
      
      QuickServiceItem(
        label: 'الأذكار',
        icon: Icons.auto_stories_rounded,
        route: AppRoutes.adhkar,
      ),
      
      QuickServiceItem(
        label: 'القرآن الكريم',
        icon: Icons.menu_book_rounded,
        route: AppRoutes.holyQuran,
      ),
      QuickServiceItem(
        label: 'المكتبة',
        icon: Icons.local_library_rounded,
        route: AppRoutes.library,
      ),
    ]);
  }
}

typedef QuickServiceNavigate = void Function(BuildContext context, String route);

/// Horizontal row of service shortcuts — single primary accent (+ optional trailing tile).
class QuickServicesRowNeutral extends ConsumerWidget {
  QuickServicesRowNeutral({
    super.key,
    List<QuickServiceItem>? items,
    this.navigate,
    this.trailingTile,
    this.height = 100,
  }) : items =
            items ?? QuickServiceItem.islamicShortcuts(newsFirst: false);

  final List<QuickServiceItem> items;
  final QuickServiceNavigate? navigate;
  /// Placed after [items], e.g. parent home "الكل".
  final Widget? trailingTile;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void go(String route) {
      ConnectivityGuard.tryNavigate(
        ref,
        () => (navigate ?? _defaultNavigate)(context, ref, route),
        context: context,
        route: route,
      );
    }

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => go(item.route),
                child: SizedBox(
                  width: 85,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          if (item.showUnreadBadge)
                            Positioned(
                              top: -2,
                              left: -2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (trailingTile != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: trailingTile!,
            ),
        ],
      ),
    );
  }
}

/// Services tab grid (3 columns).
class QuickServicesGrid extends ConsumerWidget {
  QuickServicesGrid({
    super.key,
    List<QuickServiceItem>? items,
  }) : items = items ?? QuickServiceItem.servicesTabGridItems();

  final List<QuickServiceItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final action = items[index];
        return GestureDetector(
          onTap: () => ConnectivityGuard.tryNavigate(
            ref,
            () => _defaultNavigate(context, ref, action.route),
            context: context,
            route: action.route,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  action.icon,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _defaultNavigate(BuildContext context, WidgetRef ref, String route) {
  if (ref.read(appRoleProvider) == AppRole.teacher &&
      sharedServiceScreenForRoute(route, teacherMode: true) != null) {
    pushSharedService(context, route);
    return;
  }
  context.push(route);
}
