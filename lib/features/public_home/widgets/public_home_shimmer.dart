import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../public_home_constants.dart';

/// Skeleton layout mirroring [PublicHomeScreen] while API data loads.
class PublicHomeShimmer extends StatelessWidget {
  const PublicHomeShimmer({super.key});

  static const _placeholder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.sizeOf(context).height * 0.45;

    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: Colors.white,
      period: const Duration(milliseconds: 1200),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                _ShimmerBox(
                  width: 36,
                  height: 36,
                  radius: 8,
                  color: _placeholder.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShimmerBox(
                    height: 16,
                    radius: 6,
                    color: _placeholder.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _ShimmerBox(
                  width: 108,
                  height: 36,
                  radius: 12,
                  color: const Color(PublicHomeConstants.accentGold)
                      .withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _ShimmerBox(
              height: heroHeight.clamp(320, 420),
              radius: 0,
              color: _placeholder,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: _ShimmerBox(height: 20, width: 120, radius: 6),
            ),
          ),
          SliverToBoxAdapter(child: _QuickServicesShimmerRow()),
          SliverToBoxAdapter(child: _SectionBlockShimmer(showHorizontalCards: true)),
          SliverToBoxAdapter(child: _SectionBlockShimmer(cardHeight: 200)),
          SliverToBoxAdapter(
            child: _SectionBlockShimmer(
              cardHeight: 260,
              horizontalItemWidth: 170,
              horizontalItemHeight: 240,
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionBlockShimmer(cardHeight: 110, denseCards: true),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: _ShimmerBox(height: 160, radius: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.height,
    this.width,
    this.radius = 12,
    this.color = PublicHomeShimmer._placeholder,
  });

  final double height;
  final double? width;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius > 0 ? BorderRadius.circular(radius) : null,
      ),
    );
  }
}

class _QuickServicesShimmerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 6; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            SizedBox(
              width: 85,
              child: Column(
                children: [
                  _ShimmerBox(width: 64, height: 64, radius: 20),
                  const SizedBox(height: 8),
                  _ShimmerBox(height: 10, width: 56, radius: 4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionBlockShimmer extends StatelessWidget {
  const _SectionBlockShimmer({
    this.cardHeight = 180,
    this.showHorizontalCards = false,
    this.horizontalItemWidth = 280,
    this.horizontalItemHeight = 200,
    this.denseCards = false,
  });

  final double cardHeight;
  final bool showHorizontalCards;
  final double horizontalItemWidth;
  final double horizontalItemHeight;
  final bool denseCards;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(height: 24, width: 88, radius: 20),
                const SizedBox(height: 12),
                _ShimmerBox(height: 22, width: 200, radius: 6),
                const SizedBox(height: 8),
                _ShimmerBox(height: 14, width: double.infinity, radius: 4),
                const SizedBox(height: 4),
                _ShimmerBox(height: 14, width: 260, radius: 4),
              ],
            ),
          ),
          if (showHorizontalCards)
            SizedBox(
              height: horizontalItemHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, __) => _ShimmerBox(
                  width: horizontalItemWidth,
                  height: horizontalItemHeight,
                  radius: 20,
                ),
              ),
            )
          else if (denseCards)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(width: 110, height: 110, radius: 12),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ShimmerBox(height: 12, width: 80, radius: 6),
                              const SizedBox(height: 10),
                              _ShimmerBox(height: 16, width: double.infinity, radius: 4),
                              const SizedBox(height: 8),
                              _ShimmerBox(height: 12, width: double.infinity, radius: 4),
                              const SizedBox(height: 6),
                              _ShimmerBox(height: 12, width: 120, radius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _ShimmerBox(height: cardHeight, radius: 20),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
