import 'package:flutter/material.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.icon,
  });

  final String title;
  final String description;
  final String imageAsset;
  final IconData icon;
}

const kOnboardingSlides = <OnboardingSlide>[
  OnboardingSlide(
    title: 'إدارة حلقات تحفيظ القرآن',
    description:
        'أنشئ حلقات، أضف الطلاب، وتابع التقدم في الحفظ والمراجعة بسهولة.',
    imageAsset:
        'assets/illustrations/onboarding/onboarding_1_quran_circles.png',
    icon: Icons.menu_book_rounded,
  ),
  
  OnboardingSlide(
    title: 'الأذكار',
    description:
        'أذكارك حصنك, اذكر الله من خلال واجهة سهلة وسلسلة',
    imageAsset: 'assets/illustrations/onboarding/onboarding_4_tasbih_dhikr.png',
    icon: Icons.volunteer_activism_rounded,
  ),
];
