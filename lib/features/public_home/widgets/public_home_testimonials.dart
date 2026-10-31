import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../models/public_index_content.dart';
import '../public_home_constants.dart';
import 'islamic_pattern_painter.dart';
import 'section_header.dart';

class PublicHomeTestimonials extends StatefulWidget {
  const PublicHomeTestimonials({super.key, required this.items});

  final List<SheikhTestimonial> items;

  @override
  State<PublicHomeTestimonials> createState() => _PublicHomeTestimonialsState();
}

class _PublicHomeTestimonialsState extends State<PublicHomeTestimonials> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return ColoredBox(
      color: const Color(0xFFEEF5F6),
      child: IslamicPatternBackground(
        opacity: 0.04,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PublicSectionHeader(meta: PublicSectionMeta.sheikhTestimonials),
            SizedBox(
              height: 220,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _TestimonialCard(item: item, index: index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.item, required this.index});

  final SheikhTestimonial item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: AppFonts.cairo(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: const Color(PublicHomeConstants.accentGold),
              height: 0.8,
            ),
          ),
          Expanded(
            child: Text(
              item.quote,
              style: AppFonts.cairo(
                fontSize: 14,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? NetworkOrAssetImage(url: item.imageUrl!)
                      : Container(
                          color: AppColors.primaryLight,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.rank,
                      style: AppFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.08, end: 0);
  }
}
