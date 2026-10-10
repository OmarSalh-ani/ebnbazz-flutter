import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import '../models/student_plan_models.dart';
import '../providers/student_plan_providers.dart';

class EditPlanRowSheet extends ConsumerStatefulWidget {
  const EditPlanRowSheet({
    super.key,
    required this.studentId,
    required this.row,
    required this.surahs,
    required this.onSaved,
    this.onMessage,
  });

  final int studentId;
  final PlanRow row;
  final List<PlanSurahOption> surahs;
  final VoidCallback onSaved;
  final void Function(String message, {bool isError})? onMessage;

  static Future<void> show(
    BuildContext context, {
    required int studentId,
    required PlanRow row,
    required List<PlanSurahOption> surahs,
    required VoidCallback onSaved,
    void Function(String message, {bool isError})? onMessage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: EditPlanRowSheet(
          studentId: studentId,
          row: row,
          surahs: surahs,
          onSaved: onSaved,
          onMessage: onMessage,
        ),
      ),
    );
  }

  @override
  ConsumerState<EditPlanRowSheet> createState() => _EditPlanRowSheetState();
}

class _EditPlanRowSheetState extends ConsumerState<EditPlanRowSheet> {
  static const _planTypeMemorizing = 'حفظ';
  static const _planTypeRevise = 'مراجعة';

  late bool _isManual;
  late int? _surahId;
  late int? _fromAyah;
  late int? _toAyah;
  late String _planType;
  late final TextEditingController _manualNameController;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isManual = widget.row.isManual;
    _surahId = widget.row.surahId > 0 ? widget.row.surahId : null;
    _fromAyah =
        widget.row.fromAyahNumber > 0 ? widget.row.fromAyahNumber : null;
    _toAyah = widget.row.toAyahNumber > 0 ? widget.row.toAyahNumber : null;
    _planType = widget.row.planType == _planTypeRevise
        ? _planTypeRevise
        : _planTypeMemorizing;
    _manualNameController = TextEditingController(text: widget.row.surahName);
    _fromController = TextEditingController(
      text: _fromAyah != null ? '$_fromAyah' : '',
    );
    _toController = TextEditingController(
      text: _toAyah != null ? '$_toAyah' : '',
    );
  }

  @override
  void dispose() {
    _manualNameController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _notify(String text, {bool isError = false}) {
    widget.onMessage?.call(text, isError: isError);
  }

  Future<void> _save() async {
    if (_isManual) {
      final name = _manualNameController.text.trim();
      final from = int.tryParse(_fromController.text.trim());
      final to = int.tryParse(_toController.text.trim());

      if (name.isEmpty ||
          from == null ||
          to == null ||
          from <= 0 ||
          to <= 0 ||
          from > to) {
        _notify('يرجى إدخال اسم السورة ونطاق آيات صحيح', isError: true);
        return;
      }

      setState(() => _isSaving = true);
      try {
        final message =
            await ref.read(studentPlanRepositoryProvider).updateRow(
                  studentId: widget.studentId,
                  rowKey: widget.row.key,
                  surahId: PlanRowInput.manualPlaceholderSurahId,
                  fromAyahNumber: from,
                  toAyahNumber: to,
                  planType: _planType,
                  surahName: name,
                );
        if (mounted) {
          Navigator.pop(context);
          widget.onSaved();
          _notify(message);
        }
      } on ApiException catch (e) {
        if (mounted) _notify(e.message, isError: true);
      } catch (_) {
        if (mounted) _notify('تعذر تحديث السطر', isError: true);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    if (_surahId == null ||
        _fromAyah == null ||
        _toAyah == null ||
        _fromAyah! <= 0 ||
        _toAyah! <= 0 ||
        _fromAyah! > _toAyah!) {
      _notify('يرجى إدخال نطاق آيات صحيح', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final message = await ref.read(studentPlanRepositoryProvider).updateRow(
            studentId: widget.studentId,
            rowKey: widget.row.key,
            surahId: _surahId!,
            fromAyahNumber: _fromAyah!,
            toAyahNumber: _toAyah!,
            planType: _planType,
          );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        _notify(message);
      }
    } on ApiException catch (e) {
      if (mounted) _notify(e.message, isError: true);
    } catch (_) {
      if (mounted) _notify('تعذر تحديث السطر', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ayahsAsync = !_isManual && _surahId != null
        ? ref.watch(surahAyahsProvider(_surahId!))
        : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تعديل السطر',
              style: AppFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPlanTypeSelector(),
            const SizedBox(height: 16),
            if (_isManual) ...[
              _buildManualFields(),
            ] else ...[
              _buildSurahDropdown(),
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
                            _fromAyah,
                            (v) => setState(() => _fromAyah = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAyahDropdown(
                            'إلى آية',
                            ayahs,
                            _toAyah,
                            (v) => setState(() => _toAyah = v),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'حفظ التعديل',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          label: 'اسم السورة',
          controller: _manualNameController,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'من آية',
                controller: _fromController,
                keyboardType: TextInputType.number,
                digitsOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'إلى آية',
                controller: _toController,
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

  Widget _buildPlanTypeSelector() {
    return Row(
      children: [_planTypeMemorizing, _planTypeRevise].map((type) {
        final selected = _planType == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: type == _planTypeRevise ? 6 : 0,
              right: type == _planTypeMemorizing ? 6 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _planType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.inputBorder,
                  ),
                ),
                child: Text(
                  type,
                  textAlign: TextAlign.center,
                  style: AppFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSurahDropdown() {
    return _buildDropdownField<int>(
      label: 'السورة',
      value: _surahId,
      items: widget.surahs
          .map(
            (s) => DropdownMenuItem<int>(
              value: s.id,
              child: Text(s.name, style: AppFonts.cairo(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() {
        _surahId = v;
        _fromAyah = null;
        _toAyah = null;
      }),
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
