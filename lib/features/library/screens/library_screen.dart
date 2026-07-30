import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../models/center_release_model.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'المكتبة',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(libraryProvider);
            await ref.read(libraryProvider.future);
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
                        'تعذر تحميل المكتبة',
                        style: AppFonts.cairo(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.invalidate(libraryProvider),
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
              onTap: (item) => context.push(AppRoutes.libraryPdf, extra: item),
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
  });

  final List<CenterReleaseModel> items;
  final void Function(CenterReleaseModel item) onTap;

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
                  'لا توجد إصدارات حالياً',
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
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
                    NetworkOrAssetImage(
                      url: item.thumbnailImage,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
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
        ),
      ),
    );
  }
}
