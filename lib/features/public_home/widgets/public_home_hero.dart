import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/router/app_routes.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../models/public_index_content.dart';
import '../public_home_constants.dart';
import '../utils/public_home_utils.dart';
import 'islamic_pattern_painter.dart';

class PublicHomeHero extends StatefulWidget {
  const PublicHomeHero({
    super.key,
    required this.slides,
    required this.masgedName,
    required this.menRegistrationEnabled,
    required this.womenRegistrationEnabled,
    required this.showActivitiesButton,
  });

  final List<HeroSlide> slides;
  final String masgedName;
  final bool menRegistrationEnabled;
  final bool womenRegistrationEnabled;
  final bool showActivitiesButton;

  @override
  State<PublicHomeHero> createState() => _PublicHomeHeroState();
}

class _PublicHomeHeroState extends State<PublicHomeHero> {
  late final PageController _pageController;
  Timer? _autoTimer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant PublicHomeHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides.length != widget.slides.length) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    if (widget.slides.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_index + 1) % widget.slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.52;
    final slides = widget.slides.isNotEmpty
        ? widget.slides
        : [HeroSlide(id: 0, imageUrl: '')];

    return SizedBox(
      height: height.clamp(360, 480),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final slide = slides[i];
              if (slide.imageUrl.isEmpty) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.splashGradient,
                  ),
                );
              }
              return NetworkOrAssetImage(url: slide.imageUrl, fit: BoxFit.cover);
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryDark.withValues(alpha: 0.55),
                  AppColors.primary.withValues(alpha: 0.82),
                  const Color(0xFF071B3A).withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          IslamicPatternBackground(
            color: Colors.white,
            opacity: 0.05,
            child: const SizedBox.expand(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  'مرحباً بكم',
                  style: AppFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(PublicHomeConstants.accentGold),
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 8),
                Text(
                  widget.masgedName.isNotEmpty
                      ? widget.masgedName
                      : PublicHomeConstants.defaultMasgedName,
                  style: AppFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.15, end: 0),
                const SizedBox(height: 12),
                Text(
                  PublicHomeConstants.heroTagline,
                  style: AppFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.55,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ).animate(delay: 120.ms).fadeIn(),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (widget.menRegistrationEnabled)
                      _HeroButton(
                        label: 'تسجيل الرجال',
                        filled: true,
                        onTap: () =>
                            launchPublicUrl(PublicHomeConstants.registrationMen),
                      ),
                    if (widget.womenRegistrationEnabled)
                      _HeroButton(
                        label: 'تسجيل النساء',
                        filled: true,
                        onTap: () => launchPublicUrl(
                          PublicHomeConstants.registrationWomen,
                        ),
                      ),
                    _HeroButton(
                      label: 'إصدارات المركز',
                      filled: false,
                      onTap: () => context.push(AppRoutes.library),
                    ),
                    if (widget.showActivitiesButton)
                      _HeroButton(
                        label: 'تعرف على الأنشطة',
                        filled: false,
                        onTap: () => context.push(AppRoutes.activities),
                      ),
                  ],
                ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
          if (slides.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _index == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _index == i
                            ? const Color(PublicHomeConstants.accentGold)
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
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

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? const Color(PublicHomeConstants.accentGold)
          : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Text(
            label,
            style: AppFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: filled ? const Color(0xFF1A1A2E) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
