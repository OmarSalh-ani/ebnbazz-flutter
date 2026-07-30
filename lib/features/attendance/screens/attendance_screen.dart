import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/student_avatar.dart';
import '../../children/models/child_model.dart';
import '../../children/providers/students_provider.dart';
import '../models/attendance_month_query.dart';
import '../providers/attendance_provider.dart';
import 'package:intl/intl.dart' as intl;

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  static const double _childSelectorHeight = 112;

  String? _selectedChildId;
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'سجل الحضور',
            style: AppFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              child: studentsAsync.when(
                loading: () => const SizedBox(
                  height: _childSelectorHeight,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => SizedBox(
                  height: _childSelectorHeight,
                  child: Center(
                    child: Text(
                      'تعذر تحميل الأبناء',
                      style: AppFonts.cairo(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                data: (children) {
                  if (children.isEmpty) {
                    return SizedBox(
                      height: _childSelectorHeight,
                      child: Center(
                        child: Text(
                          'لا يوجد أبناء مسجلون',
                          style: AppFonts.cairo(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: _childSelectorHeight,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: children.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 20),
                      itemBuilder: (context, index) => Align(
                        alignment: Alignment.center,
                        child: _buildChildChip(children[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            if (_selectedChildId == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'يرجى اختيار الطالب لعرض السجل',
                        style: AppFonts.cairo(
                          fontSize: 16,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(child: _buildAttendanceBody(_selectedChildId!)),
          ],
        ),
      ),
    );
  }

  Widget _buildChildChip(ChildModel child) {
    final isSelected = _selectedChildId == child.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedChildId = child.id),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: StudentAvatar(imageUrl: child.avatarUrl, size: 56),
            ),
            const SizedBox(height: 4),
            Text(
              child.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppFonts.cairo(
                fontSize: 12,
                height: 1.1,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceBody(String studentId) {
    final query = AttendanceMonthQuery(
      studentId: studentId,
      year: _selectedYear,
      month: _selectedMonth,
    );
    final attendanceAsync = ref.watch(studentAttendanceProvider(query));
    final monthLabel = intl.DateFormat('MMMM yyyy', 'ar').format(
      DateTime(_selectedYear, _selectedMonth),
    );

    return attendanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'تعذر تحميل سجل الحضور',
              style: AppFonts.cairo(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(studentAttendanceProvider(query)),
              child: Text('إعادة المحاولة', style: AppFonts.cairo()),
            ),
          ],
        ),
      ),
      data: (attendanceData) {
        if (attendanceData.isEmpty) {
          return Column(
            children: [
              _buildMonthFilterBar(monthLabel),
              Expanded(
                child: Center(
                  child: Text(
                    'لا يوجد سجل حضور لهذا الشهر',
                    style: AppFonts.cairo(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildMonthFilterBar(monthLabel),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('حضور', Colors.green),
                  _buildLegendItem('غياب', Colors.red),
                  _buildLegendItem('تأخير', Colors.orange),
                  _buildLegendItem('اجازة', Colors.blueGrey),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(studentAttendanceProvider(query));
                  await ref.read(studentAttendanceProvider(query).future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: attendanceData.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = attendanceData[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: data.statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: data.statusColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.day,
                                  style: AppFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  data.date,
                                  style: AppFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            data.status,
                            style: AppFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: data.statusColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthFilterBar(String monthLabel) {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedYear == now.year && _selectedMonth == now.month;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              monthLabel,
              style: AppFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (!isCurrentMonth)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedYear = now.year;
                  _selectedMonth = now.month;
                });
              },
              child: Text(
                'الشهر الحالي',
                style: AppFonts.cairo(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          InkWell(
            onTap: _pickMonth,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'تصفية',
                    style: AppFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
