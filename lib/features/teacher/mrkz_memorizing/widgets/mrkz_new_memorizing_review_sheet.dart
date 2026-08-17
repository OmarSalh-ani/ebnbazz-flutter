import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';

import '../models/mrkz_memorizing_item.dart';
import '../providers/mrkz_memorizing_providers.dart';

class MrkzNewMemorizingReviewSheet extends ConsumerStatefulWidget {
  const MrkzNewMemorizingReviewSheet({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.onSaved,
    this.editItem,
  });

  final int studentId;
  final String studentName;
  final VoidCallback onSaved;
  final MrkzMemorizingItem? editItem;

  static Future<void> show(
    BuildContext context, {
    required int studentId,
    required String studentName,
    required VoidCallback onSaved,
    MrkzMemorizingItem? editItem,
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
        child: MrkzNewMemorizingReviewSheet(
          studentId: studentId,
          studentName: studentName,
          onSaved: onSaved,
          editItem: editItem,
        ),
      ),
    );
  }

  @override
  ConsumerState<MrkzNewMemorizingReviewSheet> createState() =>
      _MrkzNewMemorizingReviewSheetState();
}

class _MrkzNewMemorizingReviewSheetState
    extends ConsumerState<MrkzNewMemorizingReviewSheet> {
  static const _typeMemorization = 'حفظ';
  static const _typeRevision = 'مراجعة';

  final _mtnNameController = TextEditingController();
  final _fromMtnController = TextEditingController();
  final _toMtnController = TextEditingController();

  late String _type;
  bool _isSaving = false;

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    _type = item?.planType ?? _typeMemorization;
    if (item != null) {
      _mtnNameController.text = item.mtnName;
      _fromMtnController.text = item.fromMtn;
      _toMtnController.text = item.toMtn;
    }
  }

  @override
  void dispose() {
    _mtnNameController.dispose();
    _fromMtnController.dispose();
    _toMtnController.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: AppFonts.cairo()),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Future<void> _save() async {
    final mtnName = _mtnNameController.text.trim();
    final fromMtn = _fromMtnController.text.trim();
    final toMtn = _toMtnController.text.trim();

    if (mtnName.isEmpty || fromMtn.isEmpty || toMtn.isEmpty) {
      _showMessage('يرجى تعبئة جميع الحقول', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(mrkzMemorizingRevisionApiProvider);
      final String message;

      if (_isEdit) {
        final item = widget.editItem!;
        message = item.planType == MrkzMemorizingItem.planTypeMemorizing
            ? await api.updateMemorizing(
                studentId: widget.studentId,
                recordId: item.id,
                mtnName: mtnName,
                fromMtn: fromMtn,
                toMtn: toMtn,
              )
            : await api.updateRevision(
                studentId: widget.studentId,
                recordId: item.id,
                mtnName: mtnName,
                fromMtn: fromMtn,
                toMtn: toMtn,
              );
      } else if (_type == _typeMemorization) {
        message = await api.createMemorizing(
          studentId: widget.studentId,
          mtnName: mtnName,
          fromMtn: fromMtn,
          toMtn: toMtn,
        );
      } else {
        message = await api.createRevision(
          studentId: widget.studentId,
          mtnName: mtnName,
          fromMtn: fromMtn,
          toMtn: toMtn,
        );
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      widget.onSaved();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message, style: AppFonts.cairo()),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (_) {
      if (mounted) _showMessage('تعذر حفظ السجل', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'تعديل السجل' : 'حفظ/مراجعة جديد',
              style: AppFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.studentName,
              style: AppFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (!_isEdit) ...[
              _buildTypeSelector(),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.mrkzPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'النوع: $_type',
                  textAlign: TextAlign.center,
                  style: AppFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mrkzPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildTextField('اسم المتن', _mtnNameController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField('من', _fromMtnController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField('إلى', _toMtnController),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: _isEdit ? 'حفظ التعديلات' : 'حفظ',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [_typeMemorization, _typeRevision].map((type) {
        final selected = _type == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: type == _typeRevision ? 6 : 0,
              right: type == _typeMemorization ? 6 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _type = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.mrkzPrimary : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        selected ? AppColors.mrkzPrimary : AppColors.inputBorder,
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

  Widget _buildTextField(String label, TextEditingController controller) {
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
              borderSide: const BorderSide(
                color: AppColors.mrkzPrimary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
