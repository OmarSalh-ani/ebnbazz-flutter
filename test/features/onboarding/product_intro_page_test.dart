import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/features/onboarding/models/onboarding_slide.dart';
import 'package:masged_parent_app/features/onboarding/screens/product_intro_page.dart';
import 'package:masged_parent_app/features/onboarding/widgets/onboarding_navigation_bar.dart';
import 'package:masged_parent_app/features/onboarding/widgets/onboarding_slide_view.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildIntro(Size size) {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: AppRoutes.productIntro,
          routes: [
            GoRoute(
              path: AppRoutes.productIntro,
              builder: (_, __) => const ProductIntroPage(),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (_, __) => const Scaffold(body: Text('Login')),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('renders all slide content at iPhone 14 size (390x844)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildIntro(const Size(390, 844)));
    await tester.pumpAndSettle();

    expect(find.text(kOnboardingSlides.first.title), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
  });

  testWidgets('renders slide view without overflow at tall phone (412x915)', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: OnboardingSlideView(
                slide: kOnboardingSlides[1],
                pageIndex: 1,
                currentPage: 1,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(kOnboardingSlides[1].title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation bar shows four dots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: OnboardingNavigationBar(
              pageCount: 4,
              currentPage: 0,
              onSkip: () {},
              onNext: () {},
              onDotTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('تخطي'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });
}
