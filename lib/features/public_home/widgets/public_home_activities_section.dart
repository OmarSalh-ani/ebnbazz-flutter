import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../models/public_index_content.dart';
import '../public_home_constants.dart';
import '../utils/public_home_utils.dart';
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
    final display = items.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PublicSectionHeader(
          meta: PublicSectionMeta.activities,
          onViewAll: items.length > limit
              ? () => launchPublicUrl(
                    '${PublicHomeConstants.websiteBase}/activities',
                  )
              : null,
        ),
        if (display.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Text(
              'لا توجد أنشطة حالياً',
              style: AppFonts.cairo(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              children: [
                for (var i = 0; i < display.length; i++)
                  Padding(
                    padding:
                        EdgeInsets.only(bottom: i < display.length - 1 ? 12 : 0),
                    child: _ActivityTile(
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

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.item,
    required this.index,
    this.fallbackLogoUrl,
  });

  final ActivityItem item;
  final int index;
  final String? fallbackLogoUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl ?? fallbackLogoUrl ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (imageUrl.isNotEmpty)
            SizedBox(
              width: 96,
              height: 96,
              child: NetworkOrAssetImage(url: imageUrl),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if ((item.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description!,
                      style: AppFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn()
        .slideY(begin: 0.05, end: 0);
  }
}
