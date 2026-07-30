import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/plan_row_status_utils.dart';
import '../models/student_plan_models.dart';
import '../providers/child_plan_provider.dart';

class ChildPlanTableSection extends ConsumerStatefulWidget {
  const ChildPlanTableSection({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<ChildPlanTableSection> createState() =>
      _ChildPlanTableSectionState();
}

class _ChildPlanTableSectionState extends ConsumerState<ChildPlanTableSection> {
  static const _memorizationType = 'حفظ';
  static const _revisionType = 'مراجعة';
  static const _pageSize = 10;

  String _planType = _memorizationType;
  int _page = 1;

  ChildPlanRowsKey get _rowsKey => ChildPlanRowsKey(
        studentId: widget.studentId,
        planType: _planType,
        page: _page,
        pageSize: _pageSize,
      );

  void _selectPlanType(String type) {
    if (_planType == type) return;
    setState(() {
      _planType = type;
      _page = 1;
    });
  }

  void _goToPage(int page) {
    if (page == _page) return;
    setState(() => _page = page);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return intl.DateFormat('yyyy/MM/dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync =
        ref.watch(childPlanOverviewProvider(widget.studentId));

    return overviewAsync.when(
      loading: () => _buildLoadingCard(),
      error: (_, __) => _buildErrorCard(
        onRetry: () =>
            ref.invalidate(childPlanOverviewProvider(widget.studentId)),
      ),
      data: (overview) {
        if (!overview.hasPlan) {
          return _buildEmptyCard('لا توجد خطة حالياً لهذا الابن');
        }
        return _buildContent(overview);
      },
    );
  }

  Widget _buildContent(ParentPlanOverview overview) {
    final rowsAsync = ref.watch(childPlanRowsProvider(_rowsKey));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOverviewHeader(overview),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildPlanTypeChips(context),
          ),
          rowsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => _buildInlineError(
              onRetry: () => ref.invalidate(childPlanRowsProvider(_rowsKey)),
            ),
            data: (paged) {
              if (paged.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'لا توجد صفوف في الخطة',
                    textAlign: TextAlign.center,
                    style: AppFonts.cairo(color: AppColors.textSecondary),
                  ),
                );
              }
              return Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: paged.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildPlanRowTile(paged.items[index]),
                  ),
                  _buildPagination(paged),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader(ParentPlanOverview overview) {
    final progress = overview.progress;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overview.planName != null && overview.planName!.isNotEmpty)
            Text(
              overview.planName!,
              style: AppFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          if (overview.memorizationLevel != null &&
              overview.memorizationLevel!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              overview.memorizationLevel!,
              style: AppFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (overview.planFromDate != null && overview.planToDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'من ${_formatDate(overview.planFromDate)} — إلى ${_formatDate(overview.planToDate)}',
              style: AppFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (progress.total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progressPercent / 100,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.progressPercent}% — حاضر: ${progress.passed} / ${progress.total}',
              style: AppFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanTypeChips(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;

    final chips = [
      _buildChip(label: 'الحفظ', type: _memorizationType),
      _buildChip(label: 'المراجعة', type: _revisionType),
    ];

    if (narrow) {
      return Wrap(spacing: 8, runSpacing: 8, children: chips);
    }

    return Row(children: chips);
  }

  Widget _buildChip({required String label, required String type}) {
    final selected = _planType == type;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: AppFonts.cairo(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        selected: selected,
        onSelected: (_) => _selectPlanType(type),
        selectedColor: AppColors.primaryLight,
        backgroundColor: AppColors.inputFill,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildPlanRowTile(ParentPlanRow row) {
    final statusText = row.displayStatus;
    final badgeColor = PlanRowStatusColors.statusColor(statusText);
    final tileColor = PlanRowStatusColors.tileColor(statusText);

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: badgeColor.withValues(alpha: 0.2)),
        ),
        title: Text(
          row.surahName.startsWith('سورة')
              ? row.surahName
              : 'سورة ${row.surahName}',
          style: AppFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'من آية ${row.fromAyahNumber} إلى آية ${row.toAyahNumber}',
            style: AppFonts.cairo(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
          ),
          child: Text(
            statusText,
            style: AppFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(PagedResult<ParentPlanRow> paged) {
    if (paged.totalPages <= 1) return const SizedBox(height: 8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 320;
        final pageLabel = Text(
          'صفحة ${paged.page} من ${paged.totalPages}',
          style: AppFonts.cairo(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        );

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: paged.page > 1
                  ? () => _goToPage(paged.page - 1)
                  : null,
              child: Text('السابق', style: AppFonts.cairo()),
            ),
            TextButton(
              onPressed: paged.page < paged.totalPages
                  ? () => _goToPage(paged.page + 1)
                  : null,
              child: Text('التالي', style: AppFonts.cairo()),
            ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: stackVertically
              ? Column(
                  children: [
                    pageLabel,
                    controls,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    pageLabel,
                    controls,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppFonts.cairo(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildErrorCard({required VoidCallback onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'تعذر تحميل جدول الخطة',
            style: AppFonts.cairo(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildInlineError({required VoidCallback onRetry}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'تعذر تحميل الصفوف',
            style: AppFonts.cairo(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('إعادة المحاولة', style: AppFonts.cairo()),
          ),
        ],
      ),
    );
  }
}
