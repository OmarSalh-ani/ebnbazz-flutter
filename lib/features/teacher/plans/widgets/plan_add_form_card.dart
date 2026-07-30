import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import '../models/student_plan_models.dart';
import '../providers/student_plan_providers.dart';

class PlanAddFormCard extends ConsumerStatefulWidget {
  const PlanAddFormCard({
    super.key,
    required this.surahs,
    required this.onRowsAdded,
    this.onMessage,
  });

  final List<PlanSurahOption> surahs;
  final void Function(List<PlanRowInput> rows) onRowsAdded;
  final void Function(String message, {bool isError})? onMessage;

  @override
  ConsumerState<PlanAddFormCard> createState() => _PlanAddFormCardState();
}

class _PlanAddFormCardState extends ConsumerState<PlanAddFormCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _planType = 'حفظ';
  bool _isExpanding = false;

  // Range tab
  int? _rangeFromSurahId;
  int? _rangeToSurahId;
  int? _rangeFromAyahStart;
  int? _rangeFromAyahEnd;
  int? _rangeToAyahStart;
  int? _rangeToAyahEnd;
  bool _rangeIsReversed = false;
  List<ExpandedPlanRowPreview>? _rangePreview;

  // Multi tab
  final List<PlanRowInput> _multiDraft = [];
  int? _multiSurahId;
  int? _multiFromAyah;
  int? _multiToAyah;

  // Single tab
  int? _singleSurahId;
  int? _singleFromAyah;
  int? _singleToAyah;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        if (!_tabController.indexIsChanging) _rangePreview = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _notify(String text, {bool isError = false}) {
    widget.onMessage?.call(text, isError: isError);
  }

  String _surahLabel(int id) {
    return widget.surahs
        .firstWhere(
          (s) => s.id == id,
          orElse: () => PlanSurahOption(id: id, name: '—'),
        )
        .name;
  }

  Future<void> _expandAndAdd({
    SurahRangeSelection? range,
    List<PlanRowInput> rows = const [],
  }) async {
    setState(() => _isExpanding = true);
    try {
      final preview = await ref.read(studentPlanRepositoryProvider).expandRows(
            planType: _planType,
            range: range,
            rows: rows,
          );
      if (preview.isEmpty) {
        _notify('لم يتم إنشاء أي سطر', isError: true);
        return;
      }
      widget.onRowsAdded(preview.map((e) => e.toInput()).toList());
      _notify('تمت إضافة ${preview.length} سطراً للجدول');
      if (range != null) {
        setState(() => _rangePreview = null);
      }
    } on ApiException catch (e) {
      _notify(e.message, isError: true);
    } catch (_) {
      _notify('تعذر توسيع الخطة', isError: true);
    } finally {
      if (mounted) setState(() => _isExpanding = false);
    }
  }

  Future<void> _previewRange() async {
    final range = _buildRangeSelection();
    if (range == null) return;

    setState(() => _isExpanding = true);
    try {
      final preview = await ref.read(studentPlanRepositoryProvider).expandRows(
            planType: _planType,
            range: range,
          );
      setState(() => _rangePreview = preview);
    } on ApiException catch (e) {
      _notify(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isExpanding = false);
    }
  }

  SurahRangeSelection? _buildRangeSelection() {
    if (_rangeFromSurahId == null ||
        _rangeToSurahId == null ||
        _rangeFromAyahStart == null ||
        _rangeFromAyahEnd == null ||
        _rangeToAyahStart == null ||
        _rangeToAyahEnd == null) {
      _notify('يرجى إكمال نطاق السور والآيات', isError: true);
      return null;
    }
    if (_rangeFromAyahStart! > _rangeFromAyahEnd!) {
      _notify('نطاق آيات سورة البداية غير صحيح', isError: true);
      return null;
    }
    if (_rangeToAyahStart! > _rangeToAyahEnd!) {
      _notify('نطاق آيات سورة النهاية غير صحيح', isError: true);
      return null;
    }

    return SurahRangeSelection(
      fromSurahId: _rangeFromSurahId!,
      fromAyahNumber: _rangeFromAyahStart!,
      fromAyahEnd: _rangeFromAyahEnd!,
      toSurahId: _rangeToSurahId!,
      toAyahStart: _rangeToAyahStart!,
      toAyahNumber: _rangeToAyahEnd!,
      isReversed: _rangeIsReversed,
      planType: _planType,
    );
  }

  void _addRangeToTable() {
    final range = _buildRangeSelection();
    if (range == null) return;
    _expandAndAdd(range: range);
  }

  void _addMultiDraftLine() {
    if (_multiSurahId == null ||
        _multiFromAyah == null ||
        _multiToAyah == null ||
        _multiFromAyah! <= 0 ||
        _multiToAyah! <= 0 ||
        _multiFromAyah! > _multiToAyah!) {
      _notify('يرجى إدخال سورة ونطاق آيات صحيح', isError: true);
      return;
    }
    setState(() {
      _multiDraft.add(
        PlanRowInput(
          surahId: _multiSurahId!,
          fromAyahNumber: _multiFromAyah!,
          toAyahNumber: _multiToAyah!,
          planType: _planType,
        ),
      );
      _multiFromAyah = null;
      _multiToAyah = null;
    });
  }

  void _addMultiToTable() {
    if (_multiDraft.isEmpty) {
      _notify('أضف سورة واحدة على الأقل', isError: true);
      return;
    }
    _expandAndAdd(rows: List.from(_multiDraft));
    setState(() => _multiDraft.clear());
  }

  void _addSingleToTable() {
    if (_singleSurahId == null ||
        _singleFromAyah == null ||
        _singleToAyah == null ||
        _singleFromAyah! > _singleToAyah!) {
      _notify('يرجى إدخال نطاق آيات صحيح', isError: true);
      return;
    }
    widget.onRowsAdded([
      PlanRowInput(
        surahId: _singleSurahId!,
        fromAyahNumber: _singleFromAyah!,
        toAyahNumber: _singleToAyah!,
        planType: _planType,
      ),
    ]);
    _notify('تمت الإضافة للجدول');
    setState(() {
      _singleFromAyah = null;
      _singleToAyah = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إضافة خطة جديدة',
                        style: AppFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'اختر طريقة الإضافة ثم احفظ الخطة',
                        style: AppFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPlanTypeChip(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelStyle: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: AppFonts.cairo(fontSize: 12),
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'من سورة إلى سورة'),
              Tab(text: 'سور متعددة'),
              Tab(text: 'سورة واحدة'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: IndexedStack(
              index: _tabController.index,
              children: [
                _buildRangeTab(),
                _buildMultiTab(),
                _buildSingleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['حفظ', 'مراجعة'].map((type) {
          final selected = _planType == type;
          return GestureDetector(
            onTap: () => setState(() => _planType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                type,
                style: AppFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRangeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('نقطة البداية', Icons.play_arrow_rounded),
        const SizedBox(height: 8),
        _buildSurahAyahRow(
          surahId: _rangeFromSurahId,
          onSurahChanged: (v) => setState(() {
            _rangeFromSurahId = v;
            _rangeFromAyahStart = null;
            _rangeFromAyahEnd = null;
            _rangePreview = null;
          }),
          fromAyah: _rangeFromAyahStart,
          toAyah: _rangeFromAyahEnd,
          onFromAyah: (v) => setState(() {
            _rangeFromAyahStart = v;
            _rangePreview = null;
          }),
          onToAyah: (v) => setState(() {
            _rangeFromAyahEnd = v;
            _rangePreview = null;
          }),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('نقطة النهاية', Icons.flag_rounded),
        const SizedBox(height: 8),
        _buildSurahAyahRow(
          surahId: _rangeToSurahId,
          onSurahChanged: (v) => setState(() {
            _rangeToSurahId = v;
            _rangeToAyahStart = null;
            _rangeToAyahEnd = null;
            _rangePreview = null;
          }),
          fromAyah: _rangeToAyahStart,
          toAyah: _rangeToAyahEnd,
          onFromAyah: (v) => setState(() {
            _rangeToAyahStart = v;
            _rangePreview = null;
          }),
          onToAyah: (v) => setState(() {
            _rangeToAyahEnd = v;
            _rangePreview = null;
          }),
        ),
        const SizedBox(height: 12),
        _buildReverseTile(),
        if (_rangePreview != null && _rangePreview!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPreviewChips(_rangePreview!),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isExpanding ? null : _previewRange,
                icon: _isExpanding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.visibility_outlined, size: 18),
                label: Text('معاينة', style: AppFonts.cairo()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'إضافة للجدول',
                isLoading: _isExpanding,
                onPressed: _isExpanding ? null : _addRangeToTable,
                height: 44,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReverseTile() {
    return Material(
      color: _rangeIsReversed
          ? AppColors.warningLight
          : AppColors.inputFill,
      borderRadius: BorderRadius.circular(12),
      child: SwitchListTile(
        value: _rangeIsReversed,
        activeThumbColor: AppColors.primary,
        title: Text(
          'عكس ترتيب القرآن',
          style: AppFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          _rangeIsReversed
              ? 'تبدأ من سورة البداية وتتجه للخلف حتى سورة النهاية'
              : 'تبدأ من سورة البداية وتتقدم في المصحف حتى سورة النهاية',
          style: AppFonts.cairo(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        secondary: Icon(
          Icons.swap_vert_rounded,
          color: _rangeIsReversed ? AppColors.warning : AppColors.primary,
        ),
        onChanged: (v) => setState(() {
          _rangeIsReversed = v;
          _rangePreview = null;
        }),
      ),
    );
  }

  Widget _buildMultiTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'أضف كل سورة بنطاق آياتها، ثم اضغط إضافة للجدول',
          style: AppFonts.cairo(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSurahAyahRow(
          surahId: _multiSurahId,
          onSurahChanged: (v) => setState(() {
            _multiSurahId = v;
            _multiFromAyah = null;
            _multiToAyah = null;
          }),
          fromAyah: _multiFromAyah,
          toAyah: _multiToAyah,
          onFromAyah: (v) => setState(() => _multiFromAyah = v),
          onToAyah: (v) => setState(() => _multiToAyah = v),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addMultiDraftLine,
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: Text('إضافة للقائمة', style: AppFonts.cairo()),
          ),
        ),
        if (_multiDraft.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _multiDraft.asMap().entries.map((entry) {
              final row = entry.value;
              final idx = entry.key;
              return Chip(
                label: Text(
                  '${_surahLabel(row.surahId)} ${row.fromAyahNumber}-${row.toAyahNumber}',
                  style: AppFonts.cairo(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () =>
                    setState(() => _multiDraft.removeAt(idx)),
                backgroundColor: AppColors.primaryLight,
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        CustomButton(
          text: _multiDraft.isEmpty
              ? 'إضافة للجدول'
              : 'إضافة ${_multiDraft.length} سور للجدول',
          isLoading: _isExpanding,
          onPressed: _isExpanding ? null : _addMultiToTable,
          height: 44,
        ),
      ],
    );
  }

  Widget _buildSingleTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSurahAyahRow(
          surahId: _singleSurahId,
          onSurahChanged: (v) => setState(() {
            _singleSurahId = v;
            _singleFromAyah = null;
            _singleToAyah = null;
          }),
          fromAyah: _singleFromAyah,
          toAyah: _singleToAyah,
          onFromAyah: (v) => setState(() => _singleFromAyah = v),
          onToAyah: (v) => setState(() => _singleToAyah = v),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'إضافة للجدول',
          onPressed: _addSingleToTable,
          height: 44,
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSurahAyahRow({
    required int? surahId,
    required ValueChanged<int?> onSurahChanged,
    required int? fromAyah,
    required int? toAyah,
    required ValueChanged<int?> onFromAyah,
    required ValueChanged<int?> onToAyah,
  }) {
    final ayahsAsync =
        surahId != null ? ref.watch(surahAyahsProvider(surahId)) : null;

    return Column(
      children: [
        _buildSurahDropdown(surahId, onSurahChanged),
        const SizedBox(height: 12),
        if (ayahsAsync != null)
          ayahsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (ayahs) {
              if (ayahs.isEmpty) return const SizedBox.shrink();
              return Row(
                children: [
                  Expanded(
                    child: _buildAyahDropdown(
                      'من آية',
                      ayahs,
                      fromAyah,
                      onFromAyah,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAyahDropdown(
                      'إلى آية',
                      ayahs,
                      toAyah,
                      onToAyah,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildSurahDropdown(int? value, ValueChanged<int?> onChanged) {
    return _buildDropdownField<int>(
      label: 'السورة',
      value: value,
      items: widget.surahs
          .map(
            (s) => DropdownMenuItem<int>(
              value: s.id,
              child: Text(s.name, style: AppFonts.cairo(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAyahDropdown(
    String label,
    List<int> ayahs,
    int? value,
    ValueChanged<int?> onChanged,
  ) {
    return _buildDropdownField<int>(
      label: label,
      value: value,
      items: ayahs
          .map(
            (n) => DropdownMenuItem<int>(
              value: n,
              child: Text('$n', style: AppFonts.cairo(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(10),
            color: AppColors.inputFill,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text('اختر', style: AppFonts.cairo(fontSize: 14)),
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewChips(List<ExpandedPlanRowPreview> rows) {
    final show = rows.length > 8 ? rows.take(8).toList() : rows;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معاينة: ${rows.length} سطر',
            style: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...show.map(
                (r) => Chip(
                  label: Text(
                    '${r.surahName} ${r.fromAyahNumber}-${r.toAyahNumber}',
                    style: AppFonts.cairo(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (rows.length > 8)
                Chip(
                  label: Text(
                    '+${rows.length - 8}',
                    style: AppFonts.cairo(fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
