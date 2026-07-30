import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../children/models/student_plan_models.dart';
import '../models/memorizing_archive_item.dart';

typedef MemorizingArchiveLoader = Future<PagedResult<MemorizingArchiveItem>>
    Function(MemorizingArchiveQuery query);

class MemorizingArchiveQuery {
  const MemorizingArchiveQuery({
    required this.page,
    this.pageSize = 20,
    this.surahSearch = '',
  });

  final int page;
  final int pageSize;
  final String surahSearch;
}

class MemorizingArchiveScreen extends ConsumerStatefulWidget {
  const MemorizingArchiveScreen({
    super.key,
    required this.studentName,
    required this.loader,
  });

  final String studentName;
  final MemorizingArchiveLoader loader;

  @override
  ConsumerState<MemorizingArchiveScreen> createState() =>
      _MemorizingArchiveScreenState();
}

class _MemorizingArchiveScreenState extends ConsumerState<MemorizingArchiveScreen> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  Timer? _debounce;
  int _page = 1;
  String _surahSearch = '';
  Future<PagedResult<MemorizingArchiveItem>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  MemorizingArchiveQuery get _query => MemorizingArchiveQuery(
        page: _page,
        pageSize: _pageSize,
        surahSearch: _surahSearch,
      );

  void _load() {
    setState(() {
      _future = widget.loader(_query);
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final term = _searchController.text.trim();
      if (term == _surahSearch) return;
      setState(() {
        _surahSearch = term;
        _page = 1;
      });
      _load();
    });
  }

  void _goToPage(int page) {
    if (page == _page) return;
    setState(() => _page = page);
    _load();
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '';
    return intl.DateFormat('yyyy/MM/dd').format(date);
  }

  Color _typeColor(String type) {
    if (type == 'مراجعة') return AppColors.warning;
    return AppColors.primary;
  }

  Color _doneColor(String isDone) {
    final normalized = isDone.trim();
    if (normalized == 'نعم') return AppColors.success;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
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
                  hintText: 'بحث بسورة البداية...',
                  hintStyle: AppFonts.cairo(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _surahSearch.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _surahSearch = '';
                              _page = 1;
                            });
                            _load();
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
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<PagedResult<MemorizingArchiveItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString());
                  }
                  final paged = snapshot.data;
                  if (paged == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (paged.items.isEmpty) {
                    return _buildEmpty();
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _load(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        for (var i = 0; i < paged.items.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _buildTile(paged.items[i]),
                        ],
                        _buildPagination(paged),
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

  Widget _buildTile(MemorizingArchiveItem item) {
    final typeColor = _typeColor(item.theType);
    final doneColor = _doneColor(item.isDone);
    final dateLabel = _formatDate(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typeColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                item.theType.isEmpty ? '—' : item.theType,
                style: AppFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ),
            if (dateLabel.isNotEmpty) ...[
              const Spacer(),
              Text(
                dateLabel,
                style: AppFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('سورة البداية', item.testFrom),
              const SizedBox(height: 4),
              _detailRow('سورة النهاية', item.testTo),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'تم الحفظ: ',
                    style: AppFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    item.isDone.isEmpty ? '—' : item.isDone,
                    style: AppFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: doneColor,
                    ),
                  ),
                ],
              ),
              if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                _detailRow('ملاحظات', item.notes!.trim()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value.isEmpty ? '—' : value,
            style: AppFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(PagedResult<MemorizingArchiveItem> paged) {
    if (paged.totalPages <= 1) return const SizedBox(height: 16);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: paged.page > 1 ? () => _goToPage(paged.page - 1) : null,
            child: Text('السابق', style: AppFonts.cairo()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'صفحة ${paged.page} من ${paged.totalPages}',
              style: AppFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: paged.page < paged.totalPages
                ? () => _goToPage(paged.page + 1)
                : null,
            child: Text('التالي', style: AppFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          _surahSearch.isNotEmpty
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
              onPressed: _load,
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
    );
  }
}
