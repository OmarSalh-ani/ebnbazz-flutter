import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../models/public_index_content.dart';

class PublicActivityTile extends StatelessWidget {
  const PublicActivityTile({
    super.key,
    required this.item,
    this.fallbackLogoUrl,
    this.index = 0,
    this.descriptionMaxLines = 3,
    this.animate = true,
  });

  final ActivityItem item;
  final String? fallbackLogoUrl;
  final int index;
  final int? descriptionMaxLines;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl ?? fallbackLogoUrl ?? '';

    final tile = Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      maxLines: descriptionMaxLines,
                      overflow: descriptionMaxLines != null
                          ? TextOverflow.ellipsis
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!animate) return tile;

    return tile
        .animate(delay: (index * 60).ms)
        .fadeIn()
        .slideY(begin: 0.05, end: 0);
  }
}
