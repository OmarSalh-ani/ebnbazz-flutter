import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/router/app_routes.dart';

import '../config/adhkar_groups.dart';
import '../models/adhkar_category_summary.dart';
import '../models/adhkar_session.dart';
import '../providers/adhkar_provider.dart';

class AdhkarGroupScreen extends ConsumerStatefulWidget {
  const AdhkarGroupScreen({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  ConsumerState<AdhkarGroupScreen> createState() => _AdhkarGroupScreenState();
}

class _AdhkarGroupScreenState extends ConsumerState<AdhkarGroupScreen> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  String _search = '';
  int _page = 1;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _search = value.trim();
        _page = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = adhkarGroupById(widget.groupId);
    if (group == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'الأذكار',
              style: AppFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
          body: Center(
            child: Text(
              'المجموعة غير موجودة',
              style: AppFonts.cairo(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final listArgs = AdhkarCategoryListArgs(
      ids: group.categoryIds,
      search: _search,
      page: _page,
      pageSize: _pageSize,
    );
    final categoriesAsync = ref.watch(adhkarCategoryListProvider(listArgs));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          title: Text(
            group.title,
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'بحث في الأذكار...',
                  hintStyle: AppFonts.cairo(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: AppFonts.cairo(),
              ),
            ),
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تعذر تحميل الأذكار',
                        style: AppFonts.cairo(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(adhkarCategoryListProvider(listArgs)),
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
                data: (result) {
                  final categories = _orderByGroupIds(
                    result.items,
                    group.categoryIds,
                  );
                  if (categories.isEmpty) {
                    return Center(
                      child: Text(
                        _search.isEmpty
                            ? 'لا توجد أذكار في هذه المجموعة'
                            : 'لا توجد نتائج للبحث',
                        style: AppFonts.cairo(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final session = AdhkarSession.sessionKeyFor(
                              groupId: widget.groupId,
                              categoryId: category.id,
                            );
                            return _SubCategoryTile(
                              category: category,
                              onTap: () => context.push(
                                AppRoutes.adhkarCategoryPath(
                                  category.id,
                                  session: session,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (result.totalPages > 1)
                        _PaginationBar(
                          page: result.page,
                          totalPages: result.totalPages,
                          totalCount: result.totalCount,
                          onPrev: _page > 1
                              ? () => setState(() => _page -= 1)
                              : null,
                          onNext: _page < result.totalPages
                              ? () => setState(() => _page += 1)
                              : null,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AdhkarCategorySummary> _orderByGroupIds(
    List<AdhkarCategorySummary> items,
    List<int> categoryIds,
  ) {
    final map = {for (final item in items) item.id: item};
    final ordered = <AdhkarCategorySummary>[];
    final seen = <int>{};

    for (final id in categoryIds) {
      if (seen.contains(id)) continue;
      final item = map[id];
      if (item != null) {
        seen.add(id);
        ordered.add(item);
      }
    }

    for (final item in items) {
      if (seen.add(item.id)) ordered.add(item);
    }

    return ordered;
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: AppColors.surface,
      child: Row(
        children: [
          Text(
            'صفحة $page من $totalPages · $totalCount',
            style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Spacer(),
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }
}

class _SubCategoryTile extends StatelessWidget {
  const _SubCategoryTile({
    required this.category,
    required this.onTap,
  });

  final AdhkarCategorySummary category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.category,
                      style: AppFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.itemsCount} ذكر',
                      style: AppFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
