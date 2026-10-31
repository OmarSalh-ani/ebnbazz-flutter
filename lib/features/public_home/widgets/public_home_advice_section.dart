import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../models/public_index_content.dart';
import '../public_home_constants.dart';
import '../utils/public_home_utils.dart';
import 'islamic_pattern_painter.dart';
import 'section_header.dart';

class PublicHomeAdviceSection extends StatelessWidget {
  const PublicHomeAdviceSection({
    super.key,
    required this.items,
    required this.limit,
    this.fallbackLogoUrl,
  });

  final List<AdviceItem> items;
  final int limit;
  final String? fallbackLogoUrl;

  @override
  Widget build(BuildContext context) {
    final display = items.take(limit).toList();

    return IslamicPatternBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PublicSectionHeader(
            meta: PublicSectionMeta.advice,
            onViewAll: items.length > limit
                ? () => launchPublicUrl(PublicHomeConstants.adviceListing)
                : null,
          ),
          if (display.isEmpty)
            _EmptyMessage(message: 'لا توجد نصائح حالياً')
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                children: [
                  for (var i = 0; i < display.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i < display.length - 1 ? 14 : 0),
                      child: _AdviceCard(
                        item: display[i],
                        fallbackLogoUrl: fallbackLogoUrl,
                        index: i,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.item,
    required this.index,
    this.fallbackLogoUrl,
  });

  final AdviceItem item;
  final int index;
  final String? fallbackLogoUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl ?? fallbackLogoUrl ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl.isNotEmpty)
            SizedBox(
              height: 160,
              child: NetworkOrAssetImage(url: imageUrl),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if ((item.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description!,
                    style: AppFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if ((item.linkUrl ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => launchPublicUrl(item.linkUrl!),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'المزيد',
                          style: AppFonts.cairo(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: (index * 70).ms)
        .fadeIn()
        .slideY(begin: 0.06, end: 0);
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            message,
            style: AppFonts.cairo(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
