import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';

import '../models/plan_row_status.dart';
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

  // Range tab
  int? _rangeFromSurahId;
  int? _rangeToSurahId;
  int? _rangeFromAyahStart;
  int? _rangeFromAyahEnd;
  int? _rangeToAyahStart;
  int? _rangeToAyahEnd;
  bool _rangeIsReversed = false;
  List<ExpandedPlanRowPreview> _rangePreview = [];
  bool _isExpanding = false;

  // Flexible tab
  int? _flexSurahId;
  int? _flexFromAyah;
  int? _flexToAyah;
  bool _flexIsDone = false;
  bool _flexIncludeNext = false;
  int? _flexNextSurahId;
  int? _flexNextFromAyah;
  int? _flexNextToAyah;

  // Manual tab
  final _manualSurahController = TextEditingController();
  final _manualFromController = TextEditingController();
  final _manualToController = TextEditingController();
  bool _manualIsDone = false;
  bool _manualIncludeNext = false;
  final _manualNextSurahController = TextEditingController();
  final _manualNextFromController = TextEditingController();
  final _manualNextToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualSurahController.dispose();
    _manualFromController.dispose();
    _manualToController.dispose();
    _manualNextSurahController.dispose();
    _manualNextFromController.dispose();
    _manualNextToController.dispose();
    super.dispose();
  }

  void _notify(String text, {bool isError = false}) {
    widget.onMessage?.call(text, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
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
            onTap: (_) => setState(() {}),
            labelStyle: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: AppFonts.cairo(fontSize: 12),
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'خطة من سورة الى سورة'),
              Tab(text: 'خطة مرنة'),
              Tab(text: 'حفظ يدوي'),
            ],
            isScrollable: true,
            tabAlignment: TabAlignment.start,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: IndexedStack(
              index: _tabController.index,
              children: [
                _buildRangeTab(),
                _buildFlexibleTab(),
                _buildManualTab(),
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
        Text(
          'من',
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        _buildSurahAyahRow(
          surahId: _rangeFromSurahId,
          onSurahChanged: (v) => setState(() {
            _rangeFromSurahId = v;
            _rangeFromAyahStart = null;
            _rangeFromAyahEnd = null;
            _rangePreview = [];
          }),
          fromAyah: _rangeFromAyahStart,
          toAyah: _rangeFromAyahEnd,
          onFromAyah: (v) => setState(() {
            _rangeFromAyahStart = v;
            _rangePreview = [];
          }),
          onToAyah: (v) => setState(() {
            _rangeFromAyahEnd = v;
            _rangePreview = [];
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'إلى',
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        _buildSurahAyahRow(
          surahId: _rangeToSurahId,
          onSurahChanged: (v) => setState(() {
            _rangeToSurahId = v;
            _rangeToAyahStart = null;
            _rangeToAyahEnd = null;
            _rangePreview = [];
          }),
          fromAyah: _rangeToAyahStart,
          toAyah: _rangeToAyahEnd,
          onFromAyah: (v) => setState(() {
            _rangeToAyahStart = v;
            _rangePreview = [];
          }),
          onToAyah: (v) => setState(() {
            _rangeToAyahEnd = v;
            _rangePreview = [];
          }),
        ),
        const SizedBox(height: 8),
        _buildReverseTile(),
        if (_rangePreview.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'معاينة (${_rangePreview.length} سطر)',
            style: AppFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _rangePreview
                .map(
                  (row) => Chip(
                    label: Text(
                      '${row.surahName} ${row.fromAyahNumber}-${row.toAyahNumber}',
                      style: AppFonts.cairo(fontSize: 12),
                    ),
                    backgroundColor: AppColors.primaryLight,
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'معاينة',
                onPressed: _isExpanding ? null : _previewRange,
                height: 44,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'إضافة للجدول',
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
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _rangeIsReversed,
      activeThumbColor: AppColors.primary,
      title: Text(
        'عكس ترتيب المصحف',
        style: AppFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        _rangeIsReversed ? 'من الأخير إلى الأول' : 'من الأول إلى الأخير',
        style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
      ),
      onChanged: (v) => setState(() {
        _rangeIsReversed = v;
        _rangePreview = [];
      }),
    );
  }

  SurahRangeSelection? _buildRangeSelection() {
    if (_rangeFromSurahId == null ||
        _rangeToSurahId == null ||
        _rangeFromAyahStart == null ||
        _rangeFromAyahEnd == null ||
        _rangeToAyahStart == null ||
        _rangeToAyahEnd == null ||
        _rangeFromAyahStart! <= 0 ||
        _rangeFromAyahEnd! <= 0 ||
        _rangeToAyahStart! <= 0 ||
        _rangeToAyahEnd! <= 0 ||
        _rangeFromAyahStart! > _rangeFromAyahEnd! ||
        _rangeToAyahStart! > _rangeToAyahEnd!) {
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

  Future<List<ExpandedPlanRowPreview>?> _expandRange() async {
    final range = _buildRangeSelection();
    if (range == null) {
      _notify('يرجى إكمال بيانات النطاق بشكل صحيح', isError: true);
      return null;
    }

    setState(() => _isExpanding = true);
    try {
      return await ref.read(studentPlanRepositoryProvider).expandRows(
            planType: _planType,
            range: range,
          );
    } on ApiException catch (e) {
      _notify(e.message, isError: true);
      return null;
    } catch (_) {
      _notify('تعذر توسيع النطاق', isError: true);
      return null;
    } finally {
      if (mounted) setState(() => _isExpanding = false);
    }
  }

  Future<void> _previewRange() async {
    final preview = await _expandRange();
    if (preview == null || !mounted) return;
    setState(() => _rangePreview = preview);
    _notify('تم إنشاء معاينة لـ ${preview.length} سطر');
  }

  Future<void> _addRangeToTable() async {
    final preview = await _expandRange();
    if (preview == null || preview.isEmpty) return;

    final rows = preview.map((row) => row.toInput()).toList();
    widget.onRowsAdded(rows);
    _notify('تمت إضافة ${rows.length} سطراً للجدول');
    setState(() {
      _rangeFromAyahStart = null;
      _rangeFromAyahEnd = null;
      _rangeToAyahStart = null;
      _rangeToAyahEnd = null;
      _rangePreview = [];
    });
  }

  Widget _buildFlexibleTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSurahAyahRow(
          surahId: _flexSurahId,
          onSurahChanged: (v) => setState(() {
            _flexSurahId = v;
            _flexFromAyah = null;
            _flexToAyah = null;
          }),
          fromAyah: _flexFromAyah,
          toAyah: _flexToAyah,
          onFromAyah: (v) => setState(() => _flexFromAyah = v),
          onToAyah: (v) => setState(() => _flexToAyah = v),
        ),
        const SizedBox(height: 12),
        ..._buildDoneNextSwitches(
          isDone: _flexIsDone,
          includeNext: _flexIncludeNext,
          onDoneChanged: (v) => setState(() => _flexIsDone = v),
          onIncludeNextChanged: (v) => setState(() => _flexIncludeNext = v),
        ),
        if (_flexIncludeNext) ...[
          const SizedBox(height: 8),
          _buildSurahAyahRow(
            surahId: _flexNextSurahId,
            onSurahChanged: (v) => setState(() {
              _flexNextSurahId = v;
              _flexNextFromAyah = null;
              _flexNextToAyah = null;
            }),
            fromAyah: _flexNextFromAyah,
            toAyah: _flexNextToAyah,
            onFromAyah: (v) => setState(() => _flexNextFromAyah = v),
            onToAyah: (v) => setState(() => _flexNextToAyah = v),
          ),
        ],
        const SizedBox(height: 16),
        CustomButton(
          text: 'إضافة للجدول',
          onPressed: _addFlexToTable,
          height: 44,
        ),
      ],
    );
  }

  Widget _buildManualTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildManualNameAyahRow(
          nameController: _manualSurahController,
          fromController: _manualFromController,
          toController: _manualToController,
        ),
        const SizedBox(height: 12),
        ..._buildDoneNextSwitches(
          isDone: _manualIsDone,
          includeNext: _manualIncludeNext,
          onDoneChanged: (v) => setState(() => _manualIsDone = v),
          onIncludeNextChanged: (v) => setState(() => _manualIncludeNext = v),
        ),
        if (_manualIncludeNext) ...[
          const SizedBox(height: 8),
          _buildManualNameAyahRow(
            nameController: _manualNextSurahController,
            fromController: _manualNextFromController,
            toController: _manualNextToController,
          ),
        ],
        const SizedBox(height: 16),
        CustomButton(
          text: 'إضافة للجدول',
          onPressed: _addManualToTable,
          height: 44,
        ),
      ],
    );
  }

  List<Widget> _buildDoneNextSwitches({
    required bool isDone,
    required bool includeNext,
    required ValueChanged<bool> onDoneChanged,
    required ValueChanged<bool> onIncludeNextChanged,
  }) {
    final doneLabel =
        _planType == 'مراجعة' ? 'تم المراجعة' : 'تم الحفظ';
    final nextLabel =
        _planType == 'مراجعة' ? 'المراجعة القادمة' : 'الحفظ القادم';

    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: isDone,
        activeThumbColor: AppColors.primary,
        title: Text(
          doneLabel,
          style: AppFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          isDone ? 'نعم' : 'لا',
          style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
        ),
        onChanged: onDoneChanged,
      ),
      const SizedBox(height: 4),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: includeNext,
        activeThumbColor: AppColors.primary,
        title: Text(
          nextLabel,
          style: AppFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'يُجدول ليوم العمل التالي',
          style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
        ),
        onChanged: onIncludeNextChanged,
      ),
    ];
  }

  void _addFlexToTable() {
    if (_flexSurahId == null ||
        _flexFromAyah == null ||
        _flexToAyah == null ||
        _flexFromAyah! <= 0 ||
        _flexToAyah! <= 0 ||
        _flexFromAyah! > _flexToAyah!) {
      _notify('يرجى إدخال سورة ونطاق آيات صحيح', isError: true);
      return;
    }

    final rows = <PlanRowInput>[
      PlanRowInput(
        surahId: _flexSurahId!,
        fromAyahNumber: _flexFromAyah!,
        toAyahNumber: _flexToAyah!,
        planType: _planType,
        status: _flexIsDone ? PlanRowStatus.pass : PlanRowStatus.pending,
      ),
    ];

    if (_flexIncludeNext) {
      if (_flexNextSurahId == null ||
          _flexNextFromAyah == null ||
          _flexNextToAyah == null ||
          _flexNextFromAyah! <= 0 ||
          _flexNextToAyah! <= 0 ||
          _flexNextFromAyah! > _flexNextToAyah!) {
        _notify('يرجى إكمال بيانات البند القادم', isError: true);
        return;
      }
      rows.add(
        PlanRowInput(
          surahId: _flexNextSurahId!,
          fromAyahNumber: _flexNextFromAyah!,
          toAyahNumber: _flexNextToAyah!,
          planType: _planType,
          status: PlanRowStatus.pending,
          useNextWorkDay: true,
        ),
      );
    }

    widget.onRowsAdded(rows);
    _notify('تمت إضافة ${rows.length} سطراً للجدول');
    setState(() {
      _flexFromAyah = null;
      _flexToAyah = null;
      _flexIsDone = false;
      _flexIncludeNext = false;
      _flexNextSurahId = null;
      _flexNextFromAyah = null;
      _flexNextToAyah = null;
    });
  }

  void _addManualToTable() {
    final name = _manualSurahController.text.trim();
    final from = int.tryParse(_manualFromController.text.trim());
    final to = int.tryParse(_manualToController.text.trim());

    if (name.isEmpty || from == null || to == null || from <= 0 || to <= 0 || from > to) {
      _notify('يرجى إدخال اسم السورة ونطاق آيات صحيح', isError: true);
      return;
    }

    final rows = <PlanRowInput>[
      PlanRowInput(
        surahId: PlanRowInput.manualPlaceholderSurahId,
        surahName: name,
        fromAyahNumber: from,
        toAyahNumber: to,
        planType: _planType,
        status: _manualIsDone ? PlanRowStatus.pass : PlanRowStatus.pending,
      ),
    ];

    if (_manualIncludeNext) {
      final nextName = _manualNextSurahController.text.trim();
      final nextFrom = int.tryParse(_manualNextFromController.text.trim());
      final nextTo = int.tryParse(_manualNextToController.text.trim());

      if (nextName.isEmpty ||
          nextFrom == null ||
          nextTo == null ||
          nextFrom <= 0 ||
          nextTo <= 0 ||
          nextFrom > nextTo) {
        _notify('يرجى إكمال بيانات البند القادم', isError: true);
        return;
      }

      rows.add(
        PlanRowInput(
          surahId: PlanRowInput.manualPlaceholderSurahId,
          surahName: nextName,
          fromAyahNumber: nextFrom,
          toAyahNumber: nextTo,
          planType: _planType,
          status: PlanRowStatus.pending,
          useNextWorkDay: true,
        ),
      );
    }

    widget.onRowsAdded(rows);
    _notify('تمت إضافة ${rows.length} سطراً للجدول');
    setState(() {
      _manualSurahController.clear();
      _manualFromController.clear();
      _manualToController.clear();
      _manualIsDone = false;
      _manualIncludeNext = false;
      _manualNextSurahController.clear();
      _manualNextFromController.clear();
      _manualNextToController.clear();
    });
  }

  Widget _buildManualNameAyahRow({
    required TextEditingController nameController,
    required TextEditingController fromController,
    required TextEditingController toController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          label: 'اسم السورة',
          controller: nameController,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'من آية',
                controller: fromController,
                keyboardType: TextInputType.number,
                digitsOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'إلى آية',
                controller: toController,
                keyboardType: TextInputType.number,
                digitsOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    bool digitsOnly = false,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters:
              digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: AppFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
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
}
