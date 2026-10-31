import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/router/app_routes.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../models/public_index_content.dart';
import '../public_home_constants.dart';
import '../utils/public_home_utils.dart';
import 'section_header.dart';

class PublicHomeNewsSection extends StatelessWidget {
  const PublicHomeNewsSection({
    super.key,
    required this.items,
    required this.limit,
  });

  final List<PublicNewsItem> items;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final display = items.take(limit).toList();
    final dateFormat = DateFormat.yMMMMd('ar');

    return ColoredBox(
      color: const Color(0xFFEEF5F6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PublicSectionHeader(
            meta: PublicSectionMeta.news,
            onViewAll: () => context.push(AppRoutes.masgedNews),
          ),
          if (display.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Text(
                'لا توجد أخبار حالياً',
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
                          EdgeInsets.only(bottom: i < display.length - 1 ? 14 : 0),
                      child: _NewsCard(
                        item: display[i],
                        dateLabel: dateFormat.format(display[i].newsDate),
                        index: i,
                        onTap: () {
                          if ((display[i].linkUrl ?? '').isNotEmpty) {
                            launchPublicUrl(display[i].linkUrl!);
                            return;
                          }
                          context.push(
                            AppRoutes.newsDetails,
                            extra: display[i].toNewsModel(),
                          );
                        },
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

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.item,
    required this.dateLabel,
    required this.index,
    required this.onTap,
  });

  final PublicNewsItem item;
  final String dateLabel;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((item.imageUrl ?? '').isNotEmpty)
              SizedBox(
                width: 110,
                height: 110,
                child: NetworkOrAssetImage(url: item.imageUrl!),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dateLabel,
                        style: AppFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: AppFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description!,
                        style: AppFonts.cairo(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'اقرأ المزيد',
                      style: AppFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn()
        .slideX(begin: 0.04, end: 0);
  }
}
