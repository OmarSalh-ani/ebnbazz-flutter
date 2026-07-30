import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../theme/onboarding_colors.dart';

class OnboardingNavigationBar extends StatelessWidget {
  const OnboardingNavigationBar({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.onSkip,
    required this.onNext,
    required this.onDotTap,
  });

  final int pageCount;
  final int currentPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Row(
          children: [
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: OnboardingColors.skipText,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              child: Text(
                'تخطي',
                style: AppFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pageCount, (index) {
                  final isActive = index == currentPage;
                  return GestureDetector(
                    onTap: () => onDotTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 12,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: isActive ? 10 : 8,
                        height: isActive ? 10 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? OnboardingColors.navy
                              : OnboardingColors.dotInactive,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Material(
              color: OnboardingColors.navy,
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: OnboardingColors.navy.withValues(alpha: 0.35),
              child: InkWell(
                onTap: onNext,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
