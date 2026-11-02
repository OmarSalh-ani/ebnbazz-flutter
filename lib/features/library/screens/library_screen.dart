import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teacher/auth/providers/auth_providers.dart';
import '../library_kind.dart';
import '../models/center_release_model.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({
    super.key,
    this.kind = LibraryKind.releases,
  });

  final LibraryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = libraryKindConfigs[kind]!;
    final libraryAsync = ref.watch(libraryProvider(kind));
    final isGuest = !ref.watch(authProvider).isAuthenticated &&
        ref.watch(authControllerProvider).valueOrNull == null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            config.title,
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            if (isGuest)
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(
                  'تسجيل الدخول',
                  style: AppFonts.cairo(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: _KindSwitcher(current: kind),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(libraryProvider(kind));
            await ref.read(libraryProvider(kind).future);
          },
          child: libraryAsync.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
            error: (_, __) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    children: [
                      Text(
                        config.loadError,
                        style: AppFonts.cairo(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.invalidate(libraryProvider(kind)),
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
            ),
            data: (items) => _LibraryGrid(
              items: items,
              emptyMessage: config.emptyMessage,
              onTap: (item) => context.push(config.pdfRoute, extra: item),
            ),
          ),
        ),
      ),
    );
  }
}

class _KindSwitcher extends StatelessWidget {
  const _KindSwitcher({required this.current});

  final LibraryKind current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          for (final kind in LibraryKind.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _KindChip(
                  label: libraryKindConfigs[kind]!.title,
                  selected: kind == current,
                  onTap: () => _openKind(context, current, kind),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openKind(BuildContext context, LibraryKind from, LibraryKind next) {
    if (next == from) return;
    final nextRoute = libraryKindConfigs[next]!.listRoute;
    final location = GoRouterState.of(context).matchedLocation;
    if (location == libraryKindConfigs[from]!.listRoute) {
      context.go(nextRoute);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LibraryScreen(kind: next),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryGrid extends StatelessWidget {
  const _LibraryGrid({
    required this.items,
    required this.onTap,
    required this.emptyMessage,
  });

  final List<CenterReleaseModel> items;
  final void Function(CenterReleaseModel item) onTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight > 0
                    ? constraints.maxHeight * 0.35
                    : 200,
              ),
              Center(
                child: Text(
                  emptyMessage,
                  style: AppFonts.cairo(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _LibraryBookCard(item: item, onTap: () => onTap(item));
      },
    );
  }
}

class _LibraryBookCard extends StatelessWidget {
  const _LibraryBookCard({
    required this.item,
    required this.onTap,
  });

  final CenterReleaseModel item;
  final VoidCallback onTap;

  Future<void> _openVoice() async {
    final uri = Uri.tryParse(item.youtubeUrl.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    child: NetworkOrAssetImage(
                      url: item.thumbnailImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Positioned(
                  top: 8,
                  left: 8,
                  child: IgnorePointer(child: _PdfBadge()),
                ),
                if (item.hasYoutubeUrl)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: GestureDetector(
                      onTap: _openVoice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.headphones_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'الإصدار الصوتي',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _PdfBadge extends StatelessWidget {
  const _PdfBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.picture_as_pdf_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}
