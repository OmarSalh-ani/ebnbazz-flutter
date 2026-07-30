import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../models/adhkar_item.dart';
import '../providers/adhkar_progress_provider.dart';
import '../providers/adhkar_provider.dart';

class AdhkarDetailScreen extends ConsumerWidget {
  const AdhkarDetailScreen({
    super.key,
    required this.categoryId,
    required this.session,
  });

  final int categoryId;
  final String session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(adhkarCategoryProvider(categoryId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: categoryAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(
            title: Text(
              'الأذكار',
              style: AppFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Scaffold(
          appBar: AppBar(
            title: Text(
              'الأذكار',
              style: AppFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
          body: Center(
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
                      ref.invalidate(adhkarCategoryProvider(categoryId)),
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
        ),
        data: (category) {
          final progressArgs = AdhkarCategoryProgressArgs(
            sessionKey: session,
            categoryId: categoryId,
          );
          final progress = ref.watch(adhkarCategoryProgressProvider(progressArgs));
          final progressNotifier =
              ref.read(adhkarCategoryProgressProvider(progressArgs).notifier);
          final completed = progressNotifier.completedCount;
          final total = progressNotifier.totalCount;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              centerTitle: true,
              title: Text(
                category.category,
                style: AppFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            body: Column(
              children: [
                if (total > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$completed/$total مكتمل',
                        textAlign: TextAlign.center,
                        style: AppFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: category.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = category.items[index];
                      final current = progress[item.id] ?? 0;
                      return _AdhkarItemCard(
                        item: item,
                        current: current,
                        onTap: () => progressNotifier.recordTap(item),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdhkarItemCard extends StatelessWidget {
  const _AdhkarItemCard({
    required this.item,
    required this.current,
    required this.onTap,
  });

  final AdhkarItem item;
  final int current;
  final VoidCallback onTap;

  bool get _isDone => current >= item.count;

  String get _countLabel {
    if (item.count == 1) return '1 مرة';
    return '${item.count} مرات';
  }

  String get _buttonLabel {
    if (_isDone) return 'تم ✓';
    if (item.count == 1) return 'تم القراءة';
    if (current == 0) return 'تم القراءة';
    return '$current/${item.count}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDone
            ? AppColors.successLight.withValues(alpha: 0.35)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDone ? AppColors.success : AppColors.border,
          width: _isDone ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _countLabel,
              style: AppFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(
            item.text,
            style: AppFonts.cairo(
              fontSize: 16,
              height: 1.8,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isDone ? null : onTap,
              style: FilledButton.styleFrom(
                backgroundColor:
                    _isDone ? AppColors.success : AppColors.primary,
                disabledBackgroundColor: AppColors.success,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _buttonLabel,
                style: AppFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
