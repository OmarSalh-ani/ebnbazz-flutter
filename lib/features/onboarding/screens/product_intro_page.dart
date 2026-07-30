import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/router/app_routes.dart';
import '../models/onboarding_slide.dart';
import '../providers/product_intro_provider.dart';
import '../theme/onboarding_colors.dart';
import '../widgets/onboarding_background.dart';
import '../widgets/onboarding_navigation_bar.dart';
import '../widgets/onboarding_slide_view.dart';

class ProductIntroPage extends ConsumerStatefulWidget {
  const ProductIntroPage({super.key});

  @override
  ConsumerState<ProductIntroPage> createState() => _ProductIntroPageState();
}

class _ProductIntroPageState extends ConsumerState<ProductIntroPage> {
  late final PageController _pageController;
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(productIntroProvider.notifier).markCompleted();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _onNext() {
    if (_currentPage >= kOnboardingSlides.length - 1) {
      _finish();
      return;
    }
    _goToPage(_currentPage + 1);
  }

  void _goToPage(int index) {
    if (index < 0 || index >= kOnboardingSlides.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingColors.background,
      body: OnboardingBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: kOnboardingSlides.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      return Directionality(
                        textDirection: TextDirection.rtl,
                        child: OnboardingSlideView(
                          slide: kOnboardingSlides[index],
                          pageIndex: index,
                          currentPage: _currentPage,
                        ),
                      );
                    },
                  ),
                ),
              ),
              OnboardingNavigationBar(
                pageCount: kOnboardingSlides.length,
                currentPage: _currentPage,
                onSkip: _finish,
                onNext: _onNext,
                onDotTap: _goToPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
