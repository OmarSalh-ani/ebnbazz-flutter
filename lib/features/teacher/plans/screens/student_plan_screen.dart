import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import '../models/plan_row_status.dart';
import '../models/student_plan_models.dart';
import '../providers/student_plan_providers.dart';
import '../widgets/plan_add_form_card.dart';
import '../widgets/edit_plan_row_sheet.dart';

class StudentPlanScreen extends ConsumerStatefulWidget {
  const StudentPlanScreen({
    super.key,
    required this.studentId,
    this.studentName,
    this.planLevelName,
    this.initialPendingRows,
  });

  final int studentId;
  final String? studentName;
  final String? planLevelName;
  final List<PlanRowInput>? initialPendingRows;

  @override
  ConsumerState<StudentPlanScreen> createState() => _StudentPlanScreenState();
}

class _StudentPlanScreenState extends ConsumerState<StudentPlanScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedPlanId;
  final List<PlanRowInput> _pendingRows = [];

  DateTime? _planStartDate;
  DateTime? _planEndDate;
  DateTime? _loadedStartDate;
  DateTime? _loadedEndDate;

  int? _syncedPlanId;

  bool _isSaving = false;
  String? _updatingRowKey;
  String? _deletingRowKey;
  bool _editMode = false;

  late final TabController _planTabController;

  static const _planTypeMemorizing = 'حفظ';
  static const _planTypeRevise = 'مراجعة';

  @override
  void initState() {
    super.initState();
    _planTabController = TabController(length: 2, vsync: this);
    _planTabController.addListener(() {
      if (!_planTabController.indexIsChanging) setState(() {});
    });
    if (widget.initialPendingRows != null) {
      _pendingRows.addAll(widget.initialPendingRows!);
    }
  }

  @override
  void dispose() {
    _planTabController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(studentPlanOverviewProvider(widget.studentId));
    if (_selectedPlanId != null) {
      ref.invalidate(
        studentPlanDetailProvider(
          StudentPlanDetailKey(
            studentId: widget.studentId,
            planId: _selectedPlanId!,
          ),
        ),
      );
    }
  }

  void _mergePendingRows(List<PlanRowInput> rows) {
    setState(() => _pendingRows.addAll(rows));
  }

  void _initDatesFromDetail(StudentPlanDetail detail) {
    if (_syncedPlanId == detail.planId) return;
    _syncedPlanId = detail.planId;
    _planStartDate = detail.planFromDate;
    _planEndDate = detail.planToDate;
    _loadedStartDate = detail.planFromDate;
    _loadedEndDate = detail.planToDate;
  }

  void _initDatesForNewPlan() {
    if (_planStartDate != null && _planEndDate != null) return;
    final today = DateTime.now();
    _planStartDate = today;
    _planEndDate = today;
  }

  bool get _datesChanged {
    if (_planStartDate == null || _planEndDate == null) return false;
    if (_loadedStartDate == null || _loadedEndDate == null) return true;
    return !_isSameDay(_planStartDate!, _loadedStartDate!) ||
        !_isSameDay(_planEndDate!, _loadedEndDate!);
  }

  bool get _canSave =>
      _pendingRows.isNotEmpty ||
      (_selectedPlanId != null && _datesChanged);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return intl.DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _planStartDate : _planEndDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _planStartDate = picked;
        if (_planEndDate != null && _planEndDate!.isBefore(picked)) {
          _planEndDate = picked;
        }
      } else {
        _planEndDate = picked;
        if (_planStartDate != null && picked.isBefore(_planStartDate!)) {
          _planStartDate = picked;
        }
      }
    });
  }

  Future<void> _savePlan(StudentPlanOverview overview) async {
    if (!_canSave) {
      _showMessage('لا توجد تغييرات للحفظ', isError: true);
      return;
    }

    if (_planStartDate == null || _planEndDate == null) {
      _showMessage('يرجى تحديد تاريخ البداية والنهاية', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(studentPlanRepositoryProvider);
      String message;

      if (_pendingRows.isNotEmpty) {
        if (_selectedPlanId == null || overview.isNewPlanMode) {
          final planId = await repo.createPlan(
            widget.studentId,
            _pendingRows,
            planStartDate: _planStartDate,
            planEndDate: _planEndDate,
          );
          _selectedPlanId = planId;
          message = 'تم إنشاء الخطة وحفظ الصفوف';
        } else {
          message = await repo.addPlanRows(
            widget.studentId,
            _selectedPlanId!,
            _pendingRows,
            planStartDate: _planStartDate,
            planEndDate: _planEndDate,
          );
        }
        setState(() => _pendingRows.clear());
      } else if (_datesChanged && _selectedPlanId != null) {
        message = await repo.updatePlanDates(
          widget.studentId,
          _selectedPlanId!,
          planStartDate: _planStartDate!,
          planEndDate: _planEndDate!,
        );
      } else {
        _showMessage('لا توجد تغييرات للحفظ', isError: true);
        return;
      }

      _loadedStartDate = _planStartDate;
      _loadedEndDate = _planEndDate;
      _refresh();
      if (mounted) _showMessage(message);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (_) {
      if (mounted) _showMessage('تعذر حفظ الخطة', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateRowStatus(
    PlanRow row,
    String status, {
    bool trackRowLoading = true,
  }) async {
    if (row.key.isEmpty) return;
    if (row.status == status) return;

    if (trackRowLoading) setState(() => _updatingRowKey = row.key);
    try {
      final message = await ref.read(studentPlanRepositoryProvider).logRowStatus(
            studentId: widget.studentId,
            rowKey: row.key,
            status: status,
            tabType: row.planType,
          );
      _refresh();
      if (mounted) _showMessage(message);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (_) {
      if (mounted) _showMessage('تعذر تحديث الحالة', isError: true);
    } finally {
      if (mounted && trackRowLoading) setState(() => _updatingRowKey = null);
    }
  }

  Future<void> _showStatusPicker(PlanRow row) async {
    if (row.key.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'تغيير الحالة',
                style: AppFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...PlanRowStatus.selectable.map((status) {
              final isCurrent = row.status == status;
              return ListTile(
                leading: Icon(
                  isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isCurrent ? AppColors.primary : AppColors.textHint,
                ),
                title: Text(
                  status,
                  style: AppFonts.cairo(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: _statusColor(status),
                  ),
                ),
                onTap: () => Navigator.pop(context, status),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await _updateRowStatus(row, selected);
  }

  Future<void> _showEditRowSheet(
    PlanRow row,
    List<PlanSurahOption> surahs,
  ) async {
    if (row.key.isEmpty) return;

    await EditPlanRowSheet.show(
      context,
      studentId: widget.studentId,
      row: row,
      surahs: surahs,
      onSaved: _refresh,
      onMessage: _showMessage,
    );
  }

  Future<void> _confirmDeleteRow(PlanRow row) async {
    if (row.key.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف السطر', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
          'هل تريد حذف ${row.surahName} (${row.fromAyahNumber}-${row.toAyahNumber})؟',
          style: AppFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'حذف',
              style: AppFonts.cairo(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteRow(row);
  }

  Future<void> _deleteRow(PlanRow row) async {
    if (row.key.isEmpty) return;

    setState(() => _deletingRowKey = row.key);
    try {
      final message = await ref.read(studentPlanRepositoryProvider).deleteRow(
            studentId: widget.studentId,
            rowKey: row.key,
          );
      _refresh();
      if (mounted) _showMessage(message);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (_) {
      if (mounted) _showMessage('تعذر حذف السطر', isError: true);
    } finally {
      if (mounted) setState(() => _deletingRowKey = null);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync =
        ref.watch(studentPlanOverviewProvider(widget.studentId));
    final formDataAsync = ref.watch(planFormDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'خطة الطالب',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(error),
        data: (overview) {
          _selectedPlanId ??= overview.suggestedPlanId ??
              (overview.plans.isNotEmpty ? overview.plans.first.id : null);

          if (_selectedPlanId == null) {
            return _buildNoPlanState(overview, formDataAsync);
          }

          final detailAsync = ref.watch(
            studentPlanDetailProvider(
              StudentPlanDetailKey(
                studentId: widget.studentId,
                planId: _selectedPlanId!,
              ),
            ),
          );

          return detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildError(error),
            data: (detail) => formDataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildError(error),
              data: (formData) => _buildContent(overview, detail, formData),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoPlanState(
    StudentPlanOverview overview,
    AsyncValue<PlanFormData> formDataAsync,
  ) {
    return formDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(error),
      data: (formData) {
          _initDatesForNewPlan();
          return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              overview.studentName.isNotEmpty
                  ? overview.studentName
                  : widget.studentName ?? '—',
              widget.planLevelName ?? '—',
              null,
              planStartDate: _planStartDate,
              planEndDate: _planEndDate,
            ),
            const SizedBox(height: 16),
            _buildPlanDatesCard(),
            const SizedBox(height: 16),
            Text(
              'لا توجد خطة لهذا الطالب. أضف صفوفاً ثم احفظ لإنشاء خطة جديدة.',
              style: AppFonts.cairo(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            PlanAddFormCard(
              surahs: formData.surahs,
              onRowsAdded: _mergePendingRows,
              onMessage: _showMessage,
            ),
            if (_pendingRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPlanTypeTabs(const [], formData.surahs),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'حفظ الخطة',
              isLoading: _isSaving,
              onPressed: _isSaving || !_canSave ? null : () => _savePlan(overview),
            ),
          ],
        ),
      );
      },
    );
  }

  Widget _buildContent(
    StudentPlanOverview overview,
    StudentPlanDetail detail,
    PlanFormData formData,
  ) {
    _initDatesFromDetail(detail);

    final displayName = detail.studentName.isNotEmpty
        ? detail.studentName
        : widget.studentName ?? overview.studentName;

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              displayName,
              detail.memorizationLevel ?? widget.planLevelName ?? '—',
              detail.progress,
              planStartDate: _planStartDate,
              planEndDate: _planEndDate,
            ),
            if (detail.plans.length > 1) ...[
              const SizedBox(height: 12),
              _buildPlanSelector(detail.plans),
            ],
            const SizedBox(height: 12),
            _buildEditModeToggle(),
            const SizedBox(height: 16),
            _buildPlanDatesCard(),
            const SizedBox(height: 24),
            PlanAddFormCard(
              surahs: formData.surahs,
              onRowsAdded: _mergePendingRows,
              onMessage: _showMessage,
            ),
            const SizedBox(height: 24),
            Text(
              'جدول الخطة',
              style: AppFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildPlanTypeTabs(detail.allRows, formData.surahs),
            const SizedBox(height: 24),
            CustomButton(
              text: 'حفظ الخطة',
              isLoading: _isSaving,
              onPressed:
                  _isSaving || !_canSave ? null : () => _savePlan(overview),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSelector(List<StudentPlanSummary> plans) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedPlanId,
          isExpanded: true,
          items: plans
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(
                    p.name,
                    style: AppFonts.cairo(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (planId) {
            if (planId == null) return;
            setState(() {
              _selectedPlanId = planId;
              _pendingRows.clear();
              _syncedPlanId = null;
              _loadedStartDate = null;
              _loadedEndDate = null;
              _planStartDate = null;
              _planEndDate = null;
              _editMode = false;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEditModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: SwitchListTile(
        value: _editMode,
        activeThumbColor: AppColors.primary,
        title: Text(
          'تفعيل التعديل',
          style: AppFonts.cairo(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'تعديل أو حذف صفوف الخطة المحفوظة',
          style: AppFonts.cairo(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        onChanged: (value) => setState(() => _editMode = value),
      ),
    );
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
              value.isEmpty ? 'اختر التاريخ' : value,
              style: AppFonts.cairo(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    String studentName,
    String level,
    PlanProgress? progress, {
    DateTime? planStartDate,
    DateTime? planEndDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment, color: Colors.white, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خطة الطالب: $studentName',
                  style: AppFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  level,
                  style: AppFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                if (planStartDate != null && planEndDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'من: ${_formatDate(planStartDate)} — إلى: ${_formatDate(planEndDate)}',
                    style: AppFonts.cairo(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الأيام المتبقية: ${progress.daysRemaining} يوم — إجمالي أيام الحلقة: ${progress.totalPlanDays} يوم',
                    style: AppFonts.cairo(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
                if (progress != null && progress.total > 0) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.progressPercent / 100,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.progressPercent}% — حاضر: ${progress.passed} / ${progress.total}',
                    style: AppFonts.cairo(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTypeTabs(
    List<PlanRow> savedRows,
    List<PlanSurahOption> surahs,
  ) {
    final memorizingRows =
        savedRows.where((r) => r.planType == _planTypeMemorizing).toList();
    final reviseRows =
        savedRows.where((r) => r.planType == _planTypeRevise).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: TabBar(
            controller: _planTabController,
            labelStyle: AppFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: AppFonts.cairo(fontSize: 14),
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'حفظ'),
              Tab(text: 'مراجعة'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IndexedStack(
          index: _planTabController.index,
          children: [
            _buildPlanTabContent(
              savedRows: memorizingRows,
              planType: _planTypeMemorizing,
              surahs: surahs,
              emptyMessage: 'لا توجد صفوف حفظ في الخطة',
            ),
            _buildPlanTabContent(
              savedRows: reviseRows,
              planType: _planTypeRevise,
              surahs: surahs,
              emptyMessage: 'لا توجد بنود مراجعة في هذه الخطة',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanTabContent({
    required List<PlanRow> savedRows,
    required String planType,
    required List<PlanSurahOption> surahs,
    required String emptyMessage,
  }) {
    final pendingForTab =
        _pendingRows.where((r) => r.planType == planType).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingForTab.isNotEmpty) ...[
          _buildPendingTable(surahs, planType: planType),
          const SizedBox(height: 12),
        ],
        _buildPlansTable(
          savedRows,
          surahs: surahs,
          emptyMessage: emptyMessage,
        ),
      ],
    );
  }

  Widget _buildPendingTable(
    List<PlanSurahOption> surahs, {
    required String planType,
  }) {
    final rows = _pendingRows
        .asMap()
        .entries
        .where((entry) => entry.value.planType == planType)
        .toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'صفوف جديدة (${rows.length})',
              style: AppFonts.cairo(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(
                () => _pendingRows.removeWhere((r) => r.planType == planType),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text('مسح الكل', style: AppFonts.cairo(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTableCard(
          title: null,
          rows: rows.map((entry) {
            final row = entry.value;
            final surah = surahs.firstWhere(
              (s) => s.id == row.surahId,
              orElse: () => PlanSurahOption(id: row.surahId, name: '—'),
            );
            return _TableRowData(
              surah: surah.name,
              from: row.fromAyahNumber,
              to: row.toAyahNumber,
              type: row.planType,
              status: 'جديد',
              onRemove: () => setState(() => _pendingRows.removeAt(entry.key)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlansTable(
    List<PlanRow> plans, {
    required List<PlanSurahOption> surahs,
    String emptyMessage = 'لا توجد صفوف في الخطة',
  }) {
    if (plans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: AppFonts.cairo(color: AppColors.textSecondary),
        ),
      );
    }

    return _buildTableCard(
      title: null,
      rows: plans
          .map(
            (plan) => _TableRowData(
              surah: plan.surahName,
              from: plan.fromAyahNumber,
              to: plan.toAyahNumber,
              type: plan.planType,
              status: plan.statusDisplay.isNotEmpty
                  ? plan.statusDisplay
                  : plan.status,
              rowKey: plan.key,
              onStatusTap: plan.key.isNotEmpty
                  ? () => _showStatusPicker(plan)
                  : null,
              onEdit: _editMode && plan.canModify
                  ? () => _showEditRowSheet(plan, surahs)
                  : null,
              onDelete: _editMode && plan.canModify
                  ? () => _confirmDeleteRow(plan)
                  : null,
            ),
          )
          .toList(),
    );
  }

  static const _tableMinWidth = 520.0;

  static const _tableColumnWidths = <int, TableColumnWidth>{
    0: FlexColumnWidth(2.5),
    1: FlexColumnWidth(1),
    2: FlexColumnWidth(1),
    3: FlexColumnWidth(1.2),
    4: FlexColumnWidth(2.5),
  };

  Widget _buildTableCard({String? title, required List<_TableRowData> rows}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                title,
                style: AppFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final table = Table(
                columnWidths: _tableColumnWidths,
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: AppColors.inputBorder.withOpacity(0.5),
                  ),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.inputBorder.withOpacity(0.8),
                        ),
                      ),
                    ),
                    children: [
                      _buildTableHeaderCell('السورة'),
                      _buildTableHeaderCell('من'),
                      _buildTableHeaderCell('إلى'),
                      _buildTableHeaderCell('النوع'),
                      _buildTableHeaderCell('الحالة'),
                    ],
                  ),
                  ...rows.map(
                    (plan) => TableRow(
                      children: [
                        _buildTableDataCell(
                          Text(plan.surah, style: AppFonts.cairo()),
                        ),
                        _buildTableDataCell(
                          Text('${plan.from}', style: AppFonts.cairo()),
                        ),
                        _buildTableDataCell(
                          Text('${plan.to}', style: AppFonts.cairo()),
                        ),
                        _buildTableDataCell(
                          Text(plan.type, style: AppFonts.cairo()),
                        ),
                        _buildTableDataCell(_buildStatusCell(plan)),
                      ],
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth < _tableMinWidth) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _tableMinWidth,
                    child: table,
                  ),
                );
              }

              return table;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        label,
        style: AppFonts.cairo(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTableDataCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }

  Widget _buildStatusCell(_TableRowData plan) {
    final statusColor = _statusColor(plan.status);
    final isRowBusy = plan.rowKey != null &&
        (_updatingRowKey == plan.rowKey || _deletingRowKey == plan.rowKey);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isRowBusy ? null : plan.onStatusTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: plan.onStatusTap != null
                  ? Border.all(color: statusColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRowBusy)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: statusColor,
                      ),
                    ),
                  )
                else ...[
                  Flexible(
                    child: Text(
                      plan.status,
                      style: AppFonts.cairo(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (plan.onStatusTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: statusColor,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (plan.onEdit != null) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.primary,
            onPressed: isRowBusy ? null : plan.onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
        if (plan.onDelete != null) ...[
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.error,
            onPressed: isRowBusy ? null : plan.onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
        if (plan.onRemove != null) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.error,
            onPressed: plan.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }

  Color _statusColor(String status) {
    if (status.contains('لم يتم')) return AppColors.error;
    if (status.contains('اعادة')) return AppColors.warning;
    if (status.contains('تم')) return AppColors.success;
    return AppColors.textHint;
  }

  Widget _buildError(Object error) {
    final message =
        error is ApiException ? error.message : 'تعذر تحميل بيانات الخطة';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: AppFonts.cairo()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: Text('إعادة المحاولة', style: AppFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableRowData {
  const _TableRowData({
    required this.surah,
    required this.from,
    required this.to,
    required this.type,
    required this.status,
    this.rowKey,
    this.onStatusTap,
    this.onEdit,
    this.onDelete,
    this.onRemove,
  });

  final String surah;
  final int from;
  final int to;
  final String type;
  final String status;
  final String? rowKey;
  final VoidCallback? onStatusTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRemove;
}
