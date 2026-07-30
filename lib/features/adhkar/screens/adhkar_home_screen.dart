import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';

import '../config/adhkar_groups.dart';
import '../widgets/adhkar_group_card.dart';
import '../widgets/adhkar_page_header.dart';

class AdhkarHomeScreen extends ConsumerWidget {
  const AdhkarHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'الأذكار والأدعية',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: AdhkarPageHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final group = kAdhkarGroups[index];
                    return AdhkarGroupCard(
                      group: group,
                      onTap: () =>
                          context.push(AppRoutes.adhkarGroupPath(group.id)),
                    );
                  },
                  childCount: kAdhkarGroups.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
