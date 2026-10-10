import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../models/student_plan_models.dart';
import '../providers/student_plan_providers.dart';
import '../widgets/plan_add_form_card.dart';

class BulkPlanAssignmentScreen extends ConsumerStatefulWidget {
  const BulkPlanAssignmentScreen({
    super.key,
    required this.students,
  });

  final List<StudentListItem> students;

  @override
  ConsumerState<BulkPlanAssignmentScreen> createState() =>
      _BulkPlanAssignmentScreenState();
}

class _BulkPlanAssignmentScreenState
    extends ConsumerState<BulkPlanAssignmentScreen> {
  final Set<int> _selectedIds = {};
  final List<PlanRowInput> _pendingRows = [];
  bool _addToExistingPlan = false;
  bool _isSaving = false;
  final _searchController = TextEditingController();
  late DateTime _planStartDate;
  late DateTime _planEndDate;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _planStartDate = today;
    _planEndDate = today.add(const Duration(days: 7));
    _selectedIds.addAll(widget.students.map((s) => s.id));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentListItem> get _filteredStudents {
    final q = _searchController.text.trim();
    if (q.isEmpty) return widget.students;
    return widget.students
        .where((s) => s.name.contains(q) || s.group.contains(q))
        .toList();
  }

  void _toggleAll(bool? select) {
    setState(() {
      if (select == true) {
        _selectedIds.addAll(_filteredStudents.map((s) => s.id));
      } else {
        for (final s in _filteredStudents) {
          _selectedIds.remove(s.id);
        }
      }
    });
  }

  Future<void> _saveBulkPlan() async {
    if (_selectedIds.isEmpty) {
      _showMessage('يرجى اختيار طالب واحد على الأقل', isError: true);
      return;
    }
    if (_pendingRows.isEmpty) {
      _showMessage('يرجى إضافة صفوف الخطة أولاً', isError: true);
      return;
    }
    if (_planEndDate.isBefore(_planStartDate)) {
      _showMessage('تاريخ النهاية يجب أن يكون بعد تاريخ البداية', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await ref.read(studentPlanRepositoryProvider).bulkAssignPlans(
            BulkAssignPlanRequest(
              studentIds: _selectedIds.toList(),
              rows: _pendingRows,
              addToExistingPlan: _addToExistingPlan,
              planStartDate: _planStartDate,
              planEndDate: _planEndDate,
            ),
          );

      if (!mounted) return;

      if (response.failedCount == 0) {
        _showMessage('تم تعيين الخطة لـ ${response.successCount} طالب');
        Navigator.pop(context, true);
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'نتيجة التعيين',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نجح: ${response.successCount} — فشل: ${response.failedCount}',
                  style: AppFonts.cairo(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: response.results
                        .where((r) => !r.success)
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${r.studentName}: ${r.message ?? "فشل"}',
                              style: AppFonts.cairo(
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('حسناً', style: AppFonts.cairo()),
            ),
          ],
        ),
      );

      if (response.successCount > 0) {
        setState(() {
          _pendingRows.clear();
          _selectedIds.removeWhere(
            (id) => response.results.any((r) => r.studentId == id && r.success),
          );
        });
      }
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (_) {
      if (mounted) _showMessage('تعذر تعيين الخطة', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  String _formatDate(DateTime date) {
    return intl.DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _planStartDate : _planEndDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _planStartDate = picked;
        if (_planEndDate.isBefore(picked)) {
          _planEndDate = picked;
        }
      } else {
        _planEndDate = picked;
        if (picked.isBefore(_planStartDate)) {
          _planStartDate = picked;
        }
      }
    });
  }

  Widget _buildPlanDatesCard() {
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
            'فترة الخطة',
            style: AppFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'تاريخ البداية',
                  value: _formatDate(_planStartDate),
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'تاريخ النهاية',
                  value: _formatDate(_planEndDate),
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
        ],
      ),
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
              value,
              style: AppFonts.cairo(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formDataAsync = ref.watch(planFormDataProvider);
    final filtered = _filteredStudents;
    final allFilteredSelected = filtered.isNotEmpty &&
        filtered.every((s) => _selectedIds.contains(s.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'خطة جماعية',
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
        data: (formData) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(planFormDataProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSelectionHeader(allFilteredSelected, filtered),
                      const SizedBox(height: 12),
                      _buildStudentList(filtered),
                      const SizedBox(height: 20),
                      _buildPlanDatesCard(),
                      const SizedBox(height: 16),
                      PlanAddFormCard(
                        surahs: formData.surahs,
                        onRowsAdded: (rows) =>
                            setState(() => _pendingRows.addAll(rows)),
                        onMessage: _showMessage,
                      ),
                      if (_pendingRows.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildPendingSummary(formData.surahs),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader(bool allSelected, List<StudentListItem> filtered) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختر الطلاب',
                      style: AppFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_selectedIds.length} من ${widget.students.length} محدد',
                      style: AppFonts.cairo(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _toggleAll(allSelected ? false : true),
                child: Text(
                  allSelected ? 'إلغاء الكل' : 'تحديد الكل',
                  style: AppFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: AppFonts.cairo(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'بحث عن طالب...',
              hintStyle: AppFonts.cairo(fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<StudentListItem> students) {
    if (students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'لا يوجد طلاب مطابقون',
          textAlign: TextAlign.center,
          style: AppFonts.cairo(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: students.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (context, index) {
          final student = students[index];
          final selected = _selectedIds.contains(student.id);
          return CheckboxListTile(
            value: selected,
            activeColor: AppColors.primary,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedIds.add(student.id);
                } else {
                  _selectedIds.remove(student.id);
                }
              });
            },
            title: Text(
              student.name,
              style: AppFonts.cairo(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${student.group} · ${student.planLevelName}',
              style: AppFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            secondary: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                student.name.isNotEmpty ? student.name[0] : '?',
                style: AppFonts.cairo(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingSummary(List<PlanSurahOption> surahs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صفوف الخطة (${_pendingRows.length})',
                style: AppFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _pendingRows.clear()),
                child: Text('مسح', style: AppFonts.cairo(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _pendingRows.take(12).map((row) {
              final name = row.isManual
                  ? row.surahName!.trim()
                  : surahs
                      .firstWhere(
                        (s) => s.id == row.surahId,
                        orElse: () =>
                            PlanSurahOption(id: row.surahId, name: '—'),
                      )
                      .name;
              return Chip(
                label: Text(
                  '$name ${row.fromAyahNumber}-${row.toAyahNumber}',
                  style: AppFonts.cairo(fontSize: 11),
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          if (_pendingRows.length > 12)
            Text(
              '+${_pendingRows.length - 12} أخرى',
              style: AppFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _addToExistingPlan,
              activeThumbColor: AppColors.primary,
              title: Text(
                'إضافة للخطة الحالية',
                style: AppFonts.cairo(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                _addToExistingPlan
                    ? 'يُضاف للخطة النشطة إن وُجدت، وإلا تُنشأ خطة جديدة'
                    : 'إنشاء خطة جديدة لكل طالب',
                style: AppFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              onChanged: (v) => setState(() => _addToExistingPlan = v),
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: _isSaving
                  ? 'جاري الحفظ...'
                  : 'تعيين الخطة لـ ${_selectedIds.length} طالب',
              isLoading: _isSaving,
              onPressed: _isSaving || _selectedIds.isEmpty ? null : _saveBulkPlan,
            ),
          ],
        ),
      ),
    );
  }
}
