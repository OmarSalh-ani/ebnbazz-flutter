import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/router/app_routes.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../../../shared/widgets/quick_services.dart';
import '../public_home_constants.dart';
import '../providers/public_home_provider.dart';
import '../widgets/public_home_activities_section.dart';
import '../widgets/public_home_advice_section.dart';
import '../widgets/public_home_footer.dart';
import '../widgets/public_home_hero.dart';
import '../widgets/public_home_library_carousel.dart';
import '../widgets/public_home_news_section.dart';
import '../widgets/public_home_register_cta.dart';
import '../widgets/public_home_shimmer.dart';
import '../widgets/public_home_testimonials.dart';

class PublicHomeScreen extends ConsumerWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(publicHomeDataProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: homeAsync.when(
          loading: () => const PublicHomeShimmer(),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(publicHomeDataProvider),
          ),
          data: (data) {
            final content = data.content;
            final reg = data.registration;
            final branding = data.branding;
            final masgedName = branding.masgedName.isNotEmpty
                ? branding.masgedName
                : PublicHomeConstants.defaultMasgedName;
            final limit = PublicHomeConstants.previewContentLimit;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(publicHomeDataProvider);
                await ref.read(publicHomeDataProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    stretch: true,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.92),
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    title: Row(
                      children: [
                        if (branding.logoUrl != null &&
                            branding.logoUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: NetworkOrAssetImage(
                                url: branding.logoUrl!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.mosque_rounded,
                            color: const Color(PublicHomeConstants.accentGold),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            masgedName,
                            style: AppFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: FilledButton(
                          onPressed: () => context.push(AppRoutes.login),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                const Color(PublicHomeConstants.accentGold),
                            foregroundColor: const Color(0xFF1A1A2E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'تسجيل الدخول',
                            style: AppFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: PublicHomeHero(
                      slides: content.heroSlides,
                      masgedName: masgedName,
                      menRegistrationEnabled: reg.menEnabled,
                      womenRegistrationEnabled: reg.womenEnabled,
                      showActivitiesButton: reg.labels.showActivitiesSection,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Text(
                        'خدمات سريعة',
                        style: AppFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: QuickServicesRowNeutral(),
                  ),
                  SliverToBoxAdapter(
                    child: PublicHomeTestimonials(
                      items: content.sheikhTestimonials,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: PublicHomeAdviceSection(
                      items: content.advice,
                      limit: limit,
                      fallbackLogoUrl: branding.logoUrl,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: PublicHomeLibrarySections(
                      centerReleases: content.centerReleases,
                      sharhs: content.sharhs,
                      manzumas: content.manzumas,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: PublicHomeNewsSection(
                      items: content.news,
                      limit: limit,
                    ),
                  ),
                  if (reg.labels.showActivitiesSection)
                    SliverToBoxAdapter(
                      child: PublicHomeActivitiesSection(
                        items: content.activities,
                        limit: limit,
                        fallbackLogoUrl: branding.logoUrl,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: PublicHomeRegisterCta(
                      menEnabled: reg.menEnabled,
                      womenEnabled: reg.womenEnabled,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: PublicHomeFooter(
                      about: content.about,
                      socialLinks: content.socialLinks,
                      masgedName: masgedName,
                      logoUrl: branding.logoUrl,
                      menRegistrationEnabled: reg.menEnabled,
                      womenRegistrationEnabled: reg.womenEnabled,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'تعذر تحميل الصفحة',
              style: AppFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.cairo(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: Text(
                'إعادة المحاولة',
                style: AppFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
