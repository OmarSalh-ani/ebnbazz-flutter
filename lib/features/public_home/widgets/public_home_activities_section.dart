import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../shared/router/app_routes.dart';
import '../models/public_index_content.dart';
import '../public_home_constants.dart';
import 'public_activity_tile.dart';
import 'section_header.dart';

class PublicHomeActivitiesSection extends StatelessWidget {
  const PublicHomeActivitiesSection({
    super.key,
    required this.items,
    required this.limit,
    this.fallbackLogoUrl,
  });

  final List<ActivityItem> items;
  final int limit;
  final String? fallbackLogoUrl;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final display = items.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PublicSectionHeader(
          meta: PublicSectionMeta.activities,
          onViewAll: () => context.push(AppRoutes.activities),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            children: [
              for (var i = 0; i < display.length; i++)
                Padding(
                  padding:
                      EdgeInsets.only(bottom: i < display.length - 1 ? 12 : 0),
                  child: PublicActivityTile(
                    item: display[i],
                    fallbackLogoUrl: fallbackLogoUrl,
                    index: i,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
