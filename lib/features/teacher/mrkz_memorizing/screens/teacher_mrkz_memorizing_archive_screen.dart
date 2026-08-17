import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../models/mrkz_memorizing_item.dart';
import '../providers/mrkz_memorizing_providers.dart';
import '../widgets/mrkz_new_memorizing_review_sheet.dart';

class TeacherMrkzMemorizingArchiveScreen extends ConsumerStatefulWidget {
  const TeacherMrkzMemorizingArchiveScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final int studentId;
  final String studentName;

  @override
  ConsumerState<TeacherMrkzMemorizingArchiveScreen> createState() =>
      _TeacherMrkzMemorizingArchiveScreenState();
}

class _TeacherMrkzMemorizingArchiveScreenState
    extends ConsumerState<TeacherMrkzMemorizingArchiveScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _mtnSearch = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  MrkzMemorizingArchiveKey get _archiveKey => MrkzMemorizingArchiveKey(
        studentId: widget.studentId,
        mtnSearch: _mtnSearch,
      );

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final term = _searchController.text.trim();
      if (term == _mtnSearch) return;
      setState(() => _mtnSearch = term);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(mrkzMemorizingArchiveProvider(_archiveKey));
    await ref.read(mrkzMemorizingArchiveProvider(_archiveKey).future);
  }

  Future<void> _editItem(MrkzMemorizingItem item) async {
    await MrkzNewMemorizingReviewSheet.show(
      context,
      studentId: widget.studentId,
      studentName: widget.studentName,
      editItem: item,
      onSaved: _refresh,
    );
  }

  Future<void> _deleteItem(MrkzMemorizingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'حذف السجل',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد حذف سجل "${item.mtnName}"؟',
          style: AppFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('إلغاء', style: AppFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('حذف', style: AppFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final api = ref.read(mrkzMemorizingRevisionApiProvider);
      final message = item.planType == MrkzMemorizingItem.planTypeMemorizing
          ? await api.deleteMemorizing(
              studentId: widget.studentId,
              recordId: item.id,
            )
          : await api.deleteRevision(
              studentId: widget.studentId,
              recordId: item.id,
            );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: AppFonts.cairo())),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: AppFonts.cairo()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '';
    return intl.DateFormat('yyyy/MM/dd').format(date);
  }

  Color _typeColor(String type) {
    if (type == MrkzMemorizingItem.planTypeRevision) {
      return AppColors.warning;
    }
    return AppColors.mrkzPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final archiveAsync = ref.watch(mrkzMemorizingArchiveProvider(_archiveKey));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أرشيف الحفظ',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
              if (widget.studentName.trim().isNotEmpty)
                Text(
                  widget.studentName,
                  style: AppFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                style: AppFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'بحث باسم المتن...',
                  hintStyle: AppFonts.cairo(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _mtnSearch.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _mtnSearch = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.mrkzPrimary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: archiveAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildError(error.toString()),
                data: (items) {
                  if (items.isEmpty) {
                    return _buildEmpty();
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _buildHeaderRow(),
                        const SizedBox(height: 8),
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _buildDataRow(items[i]),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mrkzPrimaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _headerCell('التاريخ', flex: 2),
          _headerCell('حفظ أو مراجعة', flex: 2),
          _headerCell('اسم المتن', flex: 3),
          _headerCell('من', flex: 2),
          _headerCell('إلى', flex: 2),
          _headerCell('إجراءات', flex: 2),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDataRow(MrkzMemorizingItem item) {
    final typeColor = _typeColor(item.planType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dataCell(_formatDate(item.createdDate), flex: 2),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: typeColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  item.planType,
                  style: AppFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ),
            ),
          ),
          _dataCell(item.mtnName, flex: 3),
          _dataCell(item.fromMtn, flex: 2),
          _dataCell(item.toMtn, flex: 2),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'تعديل',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.mrkzPrimary,
                  onPressed: () => _editItem(item),
                ),
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  onPressed: () => _deleteItem(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(String value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        value.isEmpty ? '—' : value,
        textAlign: TextAlign.center,
        style: AppFonts.cairo(
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          _mtnSearch.isNotEmpty
              ? 'لا توجد سجلات مطابقة للبحث'
              : 'لا توجد سجلات في أرشيف الحفظ',
          textAlign: TextAlign.center,
          style: AppFonts.cairo(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.cairo(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _refresh,
              child: Text(
                'إعادة المحاولة',
                style: AppFonts.cairo(
                  color: AppColors.mrkzPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
