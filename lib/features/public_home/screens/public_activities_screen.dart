import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/router/app_routes.dart';
import '../providers/public_home_provider.dart';
import '../public_home_constants.dart';
import '../widgets/public_activity_tile.dart';

class PublicActivitiesScreen extends ConsumerWidget {
  const PublicActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(publicHomeDataProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            PublicSectionMeta.activities.title,
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: homeAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.35),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (_, __) => _ErrorBody(
            onRetry: () => ref.invalidate(publicHomeDataProvider),
          ),
          data: (data) {
            if (!data.registration.labels.showActivitiesSection) {
              return _DisabledBody(
                onBack: () => context.go(AppRoutes.publicHome),
              );
            }

            final items = data.content.activities;
            final logoUrl = data.branding.logoUrl;

            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                  Center(
                    child: Text(
                      'لا توجد أنشطة حالياً',
                      style: AppFonts.cairo(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(publicHomeDataProvider);
                await ref.read(publicHomeDataProvider.future);
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                itemCount: items.length + 1,
                separatorBuilder: (_, index) {
                  if (index == 0) return const SizedBox(height: 16);
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PublicSectionMeta.activities.badge,
                          style: AppFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8B6914),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          PublicSectionMeta.activities.subtitle,
                          style: AppFonts.cairo(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  }
                  final item = items[index - 1];
                  return PublicActivityTile(
                    item: item,
                    fallbackLogoUrl: logoUrl,
                    index: index - 1,
                    descriptionMaxLines: null,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
        Center(
          child: Column(
            children: [
              Text(
                'تعذر تحميل الأنشطة',
                style: AppFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'إعادة المحاولة',
                  style: AppFonts.cairo(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisabledBody extends StatelessWidget {
  const _DisabledBody({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'قسم الأنشطة غير متاح حالياً',
              textAlign: TextAlign.center,
              style: AppFonts.cairo(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onBack,
              child: Text(
                'العودة للرئيسية',
                style: AppFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
