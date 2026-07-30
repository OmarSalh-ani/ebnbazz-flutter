import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:masged_parent_app/shared/router/app_routes.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_or_asset_image.dart';
import '../models/news_model.dart';
import '../providers/news_provider.dart';
import '../providers/news_read_provider.dart';

class MasgedNewsScreen extends ConsumerWidget {
  const MasgedNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    ref.listen(newsProvider, (_, next) {
      next.whenData((news) {
        if (news.isNotEmpty) {
          ref
              .read(newsReadProvider.notifier)
              .markAllAsRead(news.map((n) => n.id));
        }
      });
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'أخبار المسجد',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(newsProvider);
            await ref.read(newsProvider.future);
          },
          child: newsAsync.when(
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
                        'تعذر تحميل الأخبار',
                        style: AppFonts.cairo(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.invalidate(newsProvider),
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
            data: (news) => _NewsList(
              news: news,
              onTap: (item) =>
                  context.push(AppRoutes.newsDetails, extra: item),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsList extends StatelessWidget {
  const _NewsList({
    required this.news,
    required this.onTap,
  });

  final List<NewsModel> news;
  final void Function(NewsModel news) onTap;

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
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
                  'لا توجد أخبار حالياً',
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

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: news.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = news[index];
        return _NewsListTile(news: item, onTap: () => onTap(item));
      },
    );
  }
}

class _NewsListTile extends StatelessWidget {
  const _NewsListTile({
    required this.news,
    required this.onTap,
  });

  final NewsModel news;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
              child: SizedBox(
                width: 110,
                height: 100,
                child: NetworkOrAssetImage(
                  url: news.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          intl.DateFormat('yyyy/MM/dd').format(news.date),
                          style: AppFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      news.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 40),
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
