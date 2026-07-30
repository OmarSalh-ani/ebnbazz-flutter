import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import '../helpers/teacher_attendance_duration.dart';
import '../models/teacher_attendance_models.dart';
import '../providers/teacher_attendance_providers.dart';

class TeacherAttendanceLogScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceLogScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceLogScreen> createState() =>
      _TeacherAttendanceLogScreenState();
}

class _TeacherAttendanceLogScreenState
    extends ConsumerState<TeacherAttendanceLogScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  late TeacherAttendanceLogQuery _activeQuery;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month, now.day);
    _activeQuery = TeacherAttendanceLogQuery(
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _formatDate(DateTime date) =>
      intl.DateFormat('yyyy/MM/dd').format(date);

  String _formatTime(DateTime? value) {
    if (value == null) return '—';
    return intl.DateFormat('hh:mm a', 'en').format(value);
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(_dateOnly(picked));
    }
  }

  void _applyFilter() {
    if (_fromDate.isAfter(_toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تاريخ البداية يجب أن يكون قبل تاريخ النهاية',
            style: AppFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _activeQuery = TeacherAttendanceLogQuery(
        fromDate: _fromDate,
        toDate: _toDate,
      );
    });
  }

  void _setCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _fromDate = DateTime(now.year, now.month, 1);
      _toDate = DateTime(now.year, now.month, now.day);
      _activeQuery = TeacherAttendanceLogQuery(
        fromDate: _fromDate,
        toDate: _toDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(teacherAttendanceLogProvider(_activeQuery));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'سجل الحضور والانصراف',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: logAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(error),
              data: (response) => _buildLogContent(response),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final now = DateTime.now();
    final isCurrentMonth = _fromDate.year == now.year &&
        _fromDate.month == now.month &&
        _fromDate.day == 1 &&
        _toDate.year == now.year &&
        _toDate.month == now.month &&
        _toDate.day == now.day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'من',
                  date: _fromDate,
                  onTap: () => _pickDate(
                    initialDate: _fromDate,
                    onSelected: (date) => setState(() => _fromDate = date),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'إلى',
                  date: _toDate,
                  onTap: () => _pickDate(
                    initialDate: _toDate,
                    onSelected: (date) => setState(() => _toDate = date),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isCurrentMonth)
                TextButton(
                  onPressed: _setCurrentMonth,
                  child: Text(
                    'الشهر الحالي',
                    style: AppFonts.cairo(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _applyFilter,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(
                  'عرض',
                  style: AppFonts.cairo(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
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
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.cairo(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: AppFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final message = error is ApiException
        ? error.message
        : 'تعذر تحميل سجل الحضور والانصراف';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.cairo(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.invalidate(teacherAttendanceLogProvider(_activeQuery)),
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

  Widget _buildLogContent(TeacherAttendanceLogResponse response) {
    if (response.records.isEmpty) {
      return Center(
        child: Text(
          'لا توجد سجلات في الفترة المحددة',
          style: AppFonts.cairo(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(teacherAttendanceLogProvider(_activeQuery)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(response.summary),
          const SizedBox(height: 16),
          ...response.records.map(_buildLogCard),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(TeacherAttendanceLogSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            label: 'أيام الحضور',
            value: '${summary.totalRecords}',
            color: AppColors.primary,
          ),
          _buildSummaryDivider(),
          _buildSummaryItem(
            label: 'مع انصراف',
            value: '${summary.totalWithDeparture}',
            color: AppColors.success,
          ),
          _buildSummaryDivider(),
          _buildSummaryItem(
            label: 'حضور فقط',
            value: '${summary.totalAttendanceOnly}',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.border,
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(TeacherAttendanceLogEntry entry) {
    final statusColor =
        entry.isDeparted ? AppColors.success : AppColors.warning;
    final statusIcon =
        entry.isDeparted ? Icons.logout_rounded : Icons.login_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.date,
                      style: AppFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      entry.day,
                      style: AppFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      entry.status,
                      style: AppFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeTile(
                  label: 'الحضور',
                  time: _formatTime(entry.attendanceDateTime),
                  icon: Icons.login_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeTile(
                  label: 'الانصراف',
                  time: _formatTime(entry.departureDateTime),
                  icon: Icons.logout_rounded,
                  color: entry.isDeparted
                      ? AppColors.textSecondary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTimeTile(
            label: 'المدة',
            time: TeacherAttendanceDuration.formatBetween(
              start: entry.attendanceDateTime,
              end: entry.departureDateTime,
              showInProgress: !entry.isDeparted,
            ),
            icon: Icons.timelapse_rounded,
            color: AppColors.primary,
            showFullText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
    bool showFullText = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  time,
                  maxLines: showFullText ? null : 2,
                  overflow: showFullText ? null : TextOverflow.ellipsis,
                  style: AppFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
