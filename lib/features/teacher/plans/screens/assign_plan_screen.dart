import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import 'package:masged_parent_app/shared/widgets/custom_text_field.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';

import '../../dashboard/models/dashboard_models.dart';
import '../models/plan_level_models.dart';
import '../providers/plan_level_providers.dart';

class AssignPlanScreen extends ConsumerStatefulWidget {
  const AssignPlanScreen({
    super.key,
    this.students = const [],
    this.preselectedStudentId,
    this.readyPlan,
  });

  final List<StudentListItem> students;
  final int? preselectedStudentId;
  final ReadyPlanItem? readyPlan;

  @override
  ConsumerState<AssignPlanScreen> createState() => _AssignPlanScreenState();
}

class _AssignPlanScreenState extends ConsumerState<AssignPlanScreen> {
  final Set<int> _selectedStudentIds = {};
  final _fromAyahController = TextEditingController();
  final _toAyahController = TextEditingController();
  final _searchController = TextEditingController();

  int? _planLevelId;
  int? _fromSurahId;
  int? _toSurahId;
  int? _fromJozz;
  int? _toJozz;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _planType = 'حفظ';
  int? _circleDaysCount;
  bool _isAssigning = false;
  bool _isLoadingDays = false;
  bool _initializedDefaults = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedStudentId != null) {
      _selectedStudentIds.add(widget.preselectedStudentId!);
    } else {
      _selectedStudentIds.addAll(widget.students.map((s) => s.id));
    }
  }

  @override
  void dispose() {
    _fromAyahController.dispose();
    _toAyahController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  PlanLevelPickItem? _selectedLevel(List<PlanLevelPickItem> levels) {
    if (_planLevelId == null) return null;
    for (final level in levels) {
      if (level.id == _planLevelId) return level;
    }
    return null;
  }

  bool _usesJozzInput(List<PlanLevelPickItem> levels) =>
      _selectedLevel(levels)?.usesJozzInput ?? false;

  void _applyReadyPlan(ReadyPlanItem plan) {
    setState(() {
      _planLevelId = plan.planLevelId;
      _fromSurahId = plan.fromSurahId;
      _toSurahId = plan.toSurahId;
      _fromAyahController.text = plan.fromAyah?.toString() ?? '';
      _toAyahController.text = plan.toAyah?.toString() ?? '';
      _fromJozz = plan.fromJozz;
      _toJozz = plan.toJozz;
      _fromDate = plan.fromDate;
      _toDate = plan.toDate;
    });
    _refreshCircleDaysCount();
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
    _refreshCircleDaysCount();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return intl.DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _refreshCircleDaysCount() async {
    final from = _formatDate(_fromDate);
    final to = _formatDate(_toDate);
    if (from.isEmpty || to.isEmpty) return;

    setState(() => _isLoadingDays = true);
    try {
      final count = await ref.read(planLevelRepositoryProvider).getCircleDaysCount(
            startDate: from,
            endDate: to,
          );
      if (mounted) setState(() => _circleDaysCount = count);
    } catch (_) {
      if (mounted) setState(() => _circleDaysCount = null);
    } finally {
      if (mounted) setState(() => _isLoadingDays = false);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: AppFonts.cairo()),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Future<void> _assignPlan() async {
    if (_selectedStudentIds.isEmpty) {
      _showMessage('يرجى اختيار طالب واحد على الأقل', isError: true);
      return;
    }
    if (_planLevelId == null || _planLevelId! <= 0) {
      _showMessage('يرجى اختيار مستوى الخطة', isError: true);
      return;
    }

    final fromDate = _formatDate(_fromDate);
    final toDate = _formatDate(_toDate);
    if (fromDate.isEmpty || toDate.isEmpty) {
      _showMessage('يرجى تحديد تاريخ البداية والنهاية', isError: true);
      return;
    }

    setState(() => _isAssigning = true);
    try {
      final message = await ref.read(planLevelRepositoryProvider).assignPlan(
            AssignPlanRequest(
              studentIds: _selectedStudentIds.toList(),
              planLevelId: _planLevelId!,
              fromSurahId: _fromSurahId ?? 1,
              toSurahId: _toSurahId ?? 1,
              fromJozz: _fromJozz,
              toJozz: _toJozz,
              fromDate: fromDate,
              toDate: toDate,
              planType: _planType,
              fromAyahNumber: int.tryParse(_fromAyahController.text.trim()),
              toAyahNumber: int.tryParse(_toAyahController.text.trim()),
            ),
          );

      if (!mounted) return;
      _showMessage(message);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('تعذر تعيين الخطة', isError: true);
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  List<IdNameOption> _filteredStudents(List<IdNameOption> students) {
    final q = _searchController.text.trim();
    if (q.isEmpty) return students;
    return students.where((s) => s.name.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formDataAsync = ref.watch(assignPlanFormDataProvider(null));
    final readyPlansAsync = ref.watch(readyPlansListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تعيين خطة للطلاب',
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
            if (widget.readyPlan != null) {
              _applyReadyPlan(widget.readyPlan!);
            } else {
              _planLevelId = formData.planLevels.isNotEmpty
                  ? formData.planLevels.first.id
                  : null;
              _fromSurahId =
                  formData.surahs.isNotEmpty ? formData.surahs.first.id : null;
              _toSurahId =
                  formData.surahs.isNotEmpty ? formData.surahs.first.id : null;
              _fromJozz =
                  formData.jozzList.isNotEmpty ? formData.jozzList.first.id : null;
              _toJozz =
                  formData.jozzList.isNotEmpty ? formData.jozzList.first.id : null;
              _fromDate = DateTime.now();
              _toDate = DateTime.now();
              _refreshCircleDaysCount();
            }
          }

          final students = formData.students.isNotEmpty
              ? formData.students
              : widget.students
                  .map((s) => IdNameOption(id: s.id, name: s.name))
                  .toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildReadyPlanPicker(readyPlansAsync),
                      const SizedBox(height: 16),
                      _buildStudentSection(students),
                      const SizedBox(height: 16),
                      _buildPlanForm(formData),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReadyPlanPicker(AsyncValue<List<ReadyPlanItem>> readyPlansAsync) {
    return readyPlansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (plans) {
        if (plans.isEmpty) return const SizedBox.shrink();
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
                'استخدام خطة جاهزة',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: null,
                  hint: Text('اختر خطة جاهزة لتعبئة النموذج', style: AppFonts.cairo(fontSize: 13)),
                  isExpanded: true,
                  items: plans
                      .map(
                        (p) => DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(
                            '#${p.id} ${p.levelName} (${p.fromSurahName} → ${p.toSurahName})',
                            style: AppFonts.cairo(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final plan = plans.firstWhere((p) => p.id == id);
                    _applyReadyPlan(plan);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentSection(List<IdNameOption> students) {
    final filtered = _filteredStudents(students);
    final allSelected =
        filtered.isNotEmpty && filtered.every((s) => _selectedStudentIds.contains(s.id));

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
            'اختر الطلاب (${_selectedStudentIds.length})',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'بحث عن طالب...',
              hintStyle: AppFonts.cairo(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.inputBorder),
              ),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: allSelected,
            tristate: true,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedStudentIds.addAll(filtered.map((s) => s.id));
                } else {
                  for (final s in filtered) {
                    _selectedStudentIds.remove(s.id);
                  }
                }
              });
            },
            title: Text('تحديد الكل', style: AppFonts.cairo(fontSize: 13)),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          ...filtered.map(
            (student) => CheckboxListTile(
              value: _selectedStudentIds.contains(student.id),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedStudentIds.add(student.id);
                  } else {
                    _selectedStudentIds.remove(student.id);
                  }
                });
              },
              title: Text(student.name, style: AppFonts.cairo(fontSize: 13)),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanForm(AssignPlanFormData formData) {
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
          _buildDropdownField<int>(
            label: 'مستوى الخطة',
            value: _planLevelId,
            items: formData.planLevels
                .map(
                  (l) => DropdownMenuItem<int>(
                    value: l.id,
                    child: Text(l.levelName, style: AppFonts.cairo(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _planLevelId = v),
          ),
          const SizedBox(height: 12),
          _buildDropdownField<String>(
            label: 'نوع الخطة',
            value: _planType,
            items: formData.planTypes
                .map(
                  (t) => DropdownMenuItem<String>(
                    value: t,
                    child: Text(t, style: AppFonts.cairo(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _planType = v ?? 'حفظ'),
          ),
          const SizedBox(height: 12),
          if (!_usesJozzInput(formData.planLevels)) ...[
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
          if (_circleDaysCount != null || _isLoadingDays) ...[
            const SizedBox(height: 12),
            Text(
              _isLoadingDays
                  ? 'جاري حساب أيام الحلقة...'
                  : 'أيام الحلقة في الفترة: $_circleDaysCount يوم',
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: CustomButton(
          text: 'تعيين الخطة',
          isLoading: _isAssigning,
          onPressed: _isAssigning ? null : _assignPlan,
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
