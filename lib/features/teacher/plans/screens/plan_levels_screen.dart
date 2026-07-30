import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import 'package:masged_parent_app/shared/widgets/custom_text_field.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';

import '../models/plan_level_models.dart';
import '../providers/plan_level_providers.dart';

class PlanLevelsScreen extends ConsumerStatefulWidget {
  const PlanLevelsScreen({super.key});

  @override
  ConsumerState<PlanLevelsScreen> createState() => _PlanLevelsScreenState();
}

class _PlanLevelsScreenState extends ConsumerState<PlanLevelsScreen> {
  final _levelNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _fromAyahController = TextEditingController();
  final _toAyahController = TextEditingController();

  int? _editLevelId;
  int? _editReadyPlanId;
  int _unitType = 0;
  int? _fromSurahId;
  int? _toSurahId;
  int? _fromJozz;
  int? _toJozz;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isSavingLevel = false;
  bool _isSavingReadyPlan = false;
  bool _initializedDefaults = false;

  static const _jozzUnitType = 2;

  @override
  void dispose() {
    _levelNameController.dispose();
    _quantityController.dispose();
    _fromAyahController.dispose();
    _toAyahController.dispose();
    super.dispose();
  }

  bool get _usesJozzInput => _unitType == _jozzUnitType;

  void _clearForm(PlanLevelFormData formData) {
    setState(() {
      _editLevelId = null;
      _editReadyPlanId = null;
      _levelNameController.clear();
      _quantityController.clear();
      _fromAyahController.clear();
      _toAyahController.clear();
      _unitType = formData.unitTypes.isNotEmpty ? formData.unitTypes.first.value : 0;
      _fromSurahId = formData.surahs.isNotEmpty ? formData.surahs.first.id : null;
      _toSurahId = formData.surahs.isNotEmpty ? formData.surahs.first.id : null;
      _fromJozz = formData.jozzList.isNotEmpty ? formData.jozzList.first.id : null;
      _toJozz = formData.jozzList.isNotEmpty ? formData.jozzList.first.id : null;
      _fromDate = DateTime.tryParse(formData.defaultFromDate);
      _toDate = DateTime.tryParse(formData.defaultToDate);
    });
  }

  void _startEditLevel(PlanLevelItem item) {
    setState(() {
      _editLevelId = item.id;
      _editReadyPlanId = null;
      _levelNameController.text = item.levelName;
      _quantityController.text = item.quantity.toString();
      _unitType = item.unitType;
    });
  }

  void _startEditReadyPlan(ReadyPlanItem item, PlanLevelFormData formData) {
    setState(() {
      _editReadyPlanId = item.id;
      _editLevelId = null;
      _levelNameController.text = item.levelName;
      _fromSurahId = item.fromSurahId;
      _toSurahId = item.toSurahId;
      _fromAyahController.text = item.fromAyah?.toString() ?? '';
      _toAyahController.text = item.toAyah?.toString() ?? '';
      _fromJozz = item.fromJozz ?? formData.jozzList.firstOrNull?.id;
      _toJozz = item.toJozz ?? formData.jozzList.firstOrNull?.id;
      _fromDate = item.fromDate;
      _toDate = item.toDate;
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return intl.DateFormat('yyyy-MM-dd').format(date);
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: AppFonts.cairo()),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Future<void> _saveLevel() async {
    final name = _levelNameController.text.trim();
    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (name.isEmpty || qty <= 0) {
      _showMessage('يرجى إدخال اسم المستوى والكمية', isError: true);
      return;
    }

    setState(() => _isSavingLevel = true);
    try {
      final repo = ref.read(planLevelRepositoryProvider);
      final request = SavePlanLevelRequest(
        levelName: name,
        unitType: _unitType,
        quantity: qty,
      );

      if (_editLevelId != null) {
        final message = await repo.updatePlanLevel(_editLevelId!, request);
        _showMessage(message);
      } else {
        await repo.createPlanLevel(request);
        _showMessage('تم حفظ المستوى');
      }

      ref.invalidate(planLevelsListProvider);
      final formData = await ref.read(planLevelFormDataProvider.future);
      _clearForm(formData);
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('تعذر حفظ المستوى', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingLevel = false);
    }
  }

  Future<void> _deleteLevel(PlanLevelItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
          'حذف مستوى "${item.levelName}"؟',
          style: AppFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: AppFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: AppFonts.cairo(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final message =
          await ref.read(planLevelRepositoryProvider).deletePlanLevel(item.id);
      ref.invalidate(planLevelsListProvider);
      _showMessage(message);
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    }
  }

  SaveReadyPlanRequest? _buildReadyPlanRequest() {
    final fromDate = _formatDate(_fromDate);
    final toDate = _formatDate(_toDate);
    if (fromDate.isEmpty || toDate.isEmpty) {
      _showMessage('يرجى تحديد تاريخ البداية والنهاية', isError: true);
      return null;
    }

    final qty = int.tryParse(_quantityController.text.trim());

    return SaveReadyPlanRequest(
      planLevelId: _editLevelId,
      levelName: _levelNameController.text.trim(),
      unitType: _unitType,
      quantity: qty,
      fromSurahId: _fromSurahId ?? 1,
      toSurahId: _toSurahId ?? 1,
      fromAyah: int.tryParse(_fromAyahController.text.trim()),
      toAyah: int.tryParse(_toAyahController.text.trim()),
      fromJozz: _fromJozz,
      toJozz: _toJozz,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<void> _saveReadyPlan() async {
    final request = _buildReadyPlanRequest();
    if (request == null) return;

    setState(() => _isSavingReadyPlan = true);
    try {
      final repo = ref.read(planLevelRepositoryProvider);
      if (_editReadyPlanId != null) {
        final message =
            await repo.updateReadyPlan(_editReadyPlanId!, request);
        _showMessage(message);
      } else {
        await repo.createReadyPlan(request);
        _showMessage('تم حفظ الخطة الجاهزة');
      }

      ref.invalidate(planLevelsListProvider);
      ref.invalidate(readyPlansListProvider);
      final formData = await ref.read(planLevelFormDataProvider.future);
      _clearForm(formData);
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('تعذر حفظ الخطة الجاهزة', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingReadyPlan = false);
    }
  }

  Future<void> _deleteReadyPlan(ReadyPlanItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('حذف الخطة الجاهزة #${item.id}؟', style: AppFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: AppFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: AppFonts.cairo(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final message =
          await ref.read(planLevelRepositoryProvider).deleteReadyPlan(item.id);
      ref.invalidate(readyPlansListProvider);
      _showMessage(message);
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formDataAsync = ref.watch(planLevelFormDataProvider);
    final levelsAsync = ref.watch(planLevelsListProvider);
    final readyPlansAsync = ref.watch(readyPlansListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'مستويات الخطة والخطط الجاهزة',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: formDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : 'تعذر تحميل البيانات',
            style: AppFonts.cairo(),
          ),
        ),
        data: (formData) {
          if (!_initializedDefaults) {
            _initializedDefaults = true;
            _fromDate = DateTime.tryParse(formData.defaultFromDate);
            _toDate = DateTime.tryParse(formData.defaultToDate);
            if (formData.surahs.isNotEmpty) {
              _fromSurahId = formData.surahs.first.id;
              _toSurahId = formData.surahs.first.id;
            }
            if (formData.jozzList.isNotEmpty) {
              _fromJozz = formData.jozzList.first.id;
              _toJozz = formData.jozzList.first.id;
            }
            if (formData.unitTypes.isNotEmpty) {
              _unitType = formData.unitTypes.first.value;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(planLevelFormDataProvider);
              ref.invalidate(planLevelsListProvider);
              ref.invalidate(readyPlansListProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildFormCard(formData),
                  const SizedBox(height: 20),
                  _buildLevelsSection(levelsAsync),
                  const SizedBox(height: 20),
                  _buildReadyPlansSection(readyPlansAsync, formData),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C8738), Color(0xFF1A5F8A)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'مستويات الخطة والخطط الجاهزة',
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'قم بإنشاء خطط خاصة بك لاستخدامها مع طلابك',
            textAlign: TextAlign.center,
            style: AppFonts.cairo(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(PlanLevelFormData formData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            label: 'اسم المستوى',
            hint: 'اسم المستوى',
            controller: _levelNameController,
          ),
          const SizedBox(height: 12),
          _buildDropdownField<int>(
            label: 'نوع القدرة',
            value: _unitType,
            items: formData.unitTypes
                .map(
                  (u) => DropdownMenuItem<int>(
                    value: u.value,
                    child: Text(u.label, style: AppFonts.cairo(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _unitType = v ?? 0),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'الكمية',
            hint: 'الكمية',
            controller: _quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          if (!_usesJozzInput) ...[
            _buildDropdownField<int>(
              label: 'من سورة',
              value: _fromSurahId,
              items: formData.surahs
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: s.id,
                      child: Text(s.name, style: AppFonts.cairo(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _fromSurahId = v),
            ),
            const SizedBox(height: 12),
            _buildDropdownField<int>(
              label: 'إلى سورة',
              value: _toSurahId,
              items: formData.surahs
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: s.id,
                      child: Text(s.name, style: AppFonts.cairo(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _toSurahId = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'من آية',
                    hint: 'اختياري',
                    controller: _fromAyahController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'إلى آية',
                    hint: 'اختياري',
                    controller: _toAyahController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildDropdownField<int>(
              label: 'من جزء',
              value: _fromJozz,
              items: formData.jozzList
                  .map(
                    (j) => DropdownMenuItem<int>(
                      value: j.id,
                      child: Text(j.name, style: AppFonts.cairo(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _fromJozz = v),
            ),
            const SizedBox(height: 12),
            _buildDropdownField<int>(
              label: 'إلى جزء',
              value: _toJozz,
              items: formData.jozzList
                  .map(
                    (j) => DropdownMenuItem<int>(
                      value: j.id,
                      child: Text(j.name, style: AppFonts.cairo(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _toJozz = v),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'تاريخ البداية',
                  value: _formatDate(_fromDate),
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'تاريخ النهاية',
                  value: _formatDate(_toDate),
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: _editLevelId != null ? 'تحديث المستوى' : 'حفظ المستوى',
                  isLoading: _isSavingLevel,
                  onPressed: _isSavingLevel ? null : _saveLevel,
                  height: 44,
                ),
              ),
              if (_editLevelId != null || _editReadyPlanId != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _clearForm(formData),
                  child: Text('إلغاء', style: AppFonts.cairo()),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: _editReadyPlanId != null
                ? 'تحديث خطة جاهزة'
                : 'حفظ خطة جاهزة',
            isLoading: _isSavingReadyPlan,
            onPressed: _isSavingReadyPlan ? null : _saveReadyPlan,
            height: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsSection(AsyncValue<List<PlanLevelItem>> levelsAsync) {
    return _buildSection(
      title: 'مستويات الخطة (الخاصة بك والعامة)',
      child: levelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(
          e is ApiException ? e.message : 'تعذر تحميل المستويات',
          style: AppFonts.cairo(color: AppColors.error),
        ),
        data: (levels) {
          if (levels.isEmpty) {
            return Text(
              'لا توجد مستويات بعد',
              textAlign: TextAlign.center,
              style: AppFonts.cairo(color: AppColors.textSecondary),
            );
          }
          return Column(
            children: levels.map((item) => _buildLevelTile(item)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildReadyPlansSection(
    AsyncValue<List<ReadyPlanItem>> readyPlansAsync,
    PlanLevelFormData formData,
  ) {
    return _buildSection(
      title: 'الخطط الجاهزة (الخاصة بك والعامة)',
      child: readyPlansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(
          e is ApiException ? e.message : 'تعذر تحميل الخطط الجاهزة',
          style: AppFonts.cairo(color: AppColors.error),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return Text(
              'لا توجد خطط جاهزة بعد',
              textAlign: TextAlign.center,
              style: AppFonts.cairo(color: AppColors.textSecondary),
            );
          }
          return Column(
            children: plans
                .map((item) => _buildReadyPlanTile(item, formData))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildLevelTile(PlanLevelItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.levelName, style: AppFonts.cairo(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${item.unitTypeDisplay} (${item.quantity})',
          style: AppFonts.cairo(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBadge(item.isGlobal ? 'عام' : 'خاص', item.isGlobal),
            if (item.canEdit) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _startEditLevel(item),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: () => _deleteLevel(item),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReadyPlanTile(ReadyPlanItem item, PlanLevelFormData formData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '#${item.id} — ${item.levelName}',
          style: AppFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          '${item.fromSurahName} → ${item.toSurahName}\n'
          '${intl.DateFormat('yyyy-MM-dd').format(item.fromDate)} — '
          '${intl.DateFormat('yyyy-MM-dd').format(item.toDate)}',
          style: AppFonts.cairo(fontSize: 11),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBadge(item.isGlobal ? 'عام' : 'خاص', item.isGlobal),
            if (item.canEdit) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _startEditReadyPlan(item, formData),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: () => _deleteReadyPlan(item),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, bool isGlobal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isGlobal ? AppColors.success : const Color(0xFF6F42C1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
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
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.inputFill,
            ),
            child: Text(
              value.isEmpty ? 'اختر التاريخ' : value,
              style: AppFonts.cairo(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
