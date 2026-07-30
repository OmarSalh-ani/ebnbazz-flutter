import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_fonts.dart';
import '../models/onboarding_slide.dart';
import '../theme/onboarding_colors.dart';

class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({
    super.key,
    required this.slide,
    required this.pageIndex,
    required this.currentPage,
  });

  final OnboardingSlide slide;
  final int pageIndex;
  final int currentPage;

  bool get _isActive => pageIndex == currentPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 58,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OnboardingColors.illustrationBackgroundLight,
                    OnboardingColors.illustrationBackground,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: OnboardingColors.illustrationBackground.withValues(
                      alpha: 0.6,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Image.asset(
                    slide.imageAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _FeatureIcon(icon: slide.icon, isActive: _isActive),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: OnboardingColors.navy,
              height: 1.4,
            ),
          )
              .animate(target: _isActive ? 1 : 0)
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: OnboardingColors.navy.withValues(alpha: 0.7),
              height: 1.6,
            ),
          )
              .animate(target: _isActive ? 1 : 0)
              .fadeIn(duration: 450.ms, delay: 80.ms, curve: Curves.easeOut)
              .slideY(begin: 0.08, end: 0, duration: 450.ms, delay: 80.ms, curve: Curves.easeOut),
        ),
        const Spacer(flex: 12),
      ],
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.icon, required this.isActive});

  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: OnboardingColors.navy,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: OnboardingColors.navy.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    )
        .animate(target: isActive ? 1 : 0)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 350.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 300.ms);
  }
}
