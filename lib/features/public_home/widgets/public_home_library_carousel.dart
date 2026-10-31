import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/router/app_routes.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../../library/library_kind.dart';
import '../models/public_index_content.dart';
import '../public_home_constants.dart';
import 'section_header.dart';

class PublicHomeLibraryCarousel extends StatelessWidget {
  const PublicHomeLibraryCarousel({
    super.key,
    required this.meta,
    required this.items,
    required this.limit,
    required this.emptyMessage,
    required this.listRoute,
    required this.pdfRoute,
  });

  final PublicSectionMeta meta;
  final List<PublicLibraryItem> items;
  final int limit;
  final String emptyMessage;
  final String listRoute;
  final String pdfRoute;

  @override
  Widget build(BuildContext context) {
    final display = items.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PublicSectionHeader(
          meta: meta,
          onViewAll: () => context.push(listRoute),
        ),
        if (display.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Text(
              emptyMessage,
              style: AppFonts.cairo(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              itemCount: display.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return _ReleaseCard(
                  item: display[index],
                  pdfRoute: pdfRoute,
                  index: index,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    required this.item,
    required this.pdfRoute,
    required this.index,
  });

  final PublicLibraryItem item;
  final String pdfRoute;
  final int index;

  Future<void> _download() async {
    final uri = Uri.tryParse(item.downloadLink);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openAudio() async {
    final url = item.youtubeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              child: InkWell(
                onTap: () => context.push(
                  pdfRoute,
                  extra: item.toCenterReleaseModel(),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if ((item.thumbnailImage ?? '').isNotEmpty)
                      NetworkOrAssetImage(url: item.thumbnailImage!)
                    else
                      Container(
                        color: AppColors.primaryLight,
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                        child: Text(
                          item.title,
                          style: AppFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniAction(
                  label: 'تصفح',
                  icon: Icons.visibility_outlined,
                  onTap: () => context.push(
                    pdfRoute,
                    extra: item.toCenterReleaseModel(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniAction(
                  label: 'تحميل',
                  icon: Icons.download_rounded,
                  onTap: _download,
                ),
              ),
            ],
          ),
          if (item.hasYoutubeUrl) ...[
            const SizedBox(height: 6),
            _MiniAction(
              label: 'الإصدار الصوتي',
              icon: Icons.headphones_rounded,
              onTap: _openAudio,
              fullWidth: true,
            ),
          ],
        ],
      ),
    )
        .animate(delay: (index * 50).ms)
        .fadeIn()
        .slideX(begin: 0.06, end: 0);
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preset carousels for the three library kinds.
class PublicHomeLibrarySections extends StatelessWidget {
  const PublicHomeLibrarySections({
    super.key,
    required this.centerReleases,
    required this.sharhs,
    required this.manzumas,
  });

  final List<PublicLibraryItem> centerReleases;
  final List<PublicLibraryItem> sharhs;
  final List<PublicLibraryItem> manzumas;

  @override
  Widget build(BuildContext context) {
    final limit = PublicHomeConstants.previewLibraryLimit;
    return Column(
      children: [
        PublicHomeLibraryCarousel(
          meta: PublicSectionMeta.centerReleases,
          items: centerReleases,
          limit: limit,
          emptyMessage: libraryKindConfigs[LibraryKind.releases]!.emptyMessage,
          listRoute: AppRoutes.library,
          pdfRoute: AppRoutes.libraryPdf,
        ),
        PublicHomeLibraryCarousel(
          meta: PublicSectionMeta.sharhs,
          items: sharhs,
          limit: limit,
          emptyMessage: libraryKindConfigs[LibraryKind.sharhs]!.emptyMessage,
          listRoute: AppRoutes.sharhs,
          pdfRoute: AppRoutes.sharhsPdf,
        ),
        PublicHomeLibraryCarousel(
          meta: PublicSectionMeta.manzumas,
          items: manzumas,
          limit: limit,
          emptyMessage: libraryKindConfigs[LibraryKind.manzumas]!.emptyMessage,
          listRoute: AppRoutes.manzumas,
          pdfRoute: AppRoutes.manzumasPdf,
        ),
      ],
    );
  }
}
