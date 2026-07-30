import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import 'package:masged_parent_app/shared/widgets/custom_text_field.dart';
import '../helpers/certificate_printer.dart';
import '../models/student_test_models.dart';
import '../models/test_certificate_models.dart';
import '../providers/student_tests_providers.dart';

class TestsScreen extends ConsumerStatefulWidget {
  const TestsScreen({
    super.key,
    required this.studentId,
    this.studentName,
    this.planLevelName,
  });

  final int studentId;
  final String? studentName;
  final String? planLevelName;

  @override
  ConsumerState<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends ConsumerState<TestsScreen> {
  static const _memMax = 70;
  static const _tajweedMax = 20;
  static const _performanceMax = 10;
  static const _totalMax = 100;

  final _memController = TextEditingController(text: '0');
  final _tajweedController = TextEditingController(text: '0');
  final _performanceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _curriculumController = TextEditingController();
  final _dateTimeController = TextEditingController();
  final _hezbControllers = List.generate(
    StudentTestHezb.cellCount,
    (_) => TextEditingController(),
  );

  DateTime _testDateTime = DateTime.now();
  int _totalScore = 0;
  String _grade = 'ضعيف';
  bool _isSaving = false;
  int? _printingTestId;

  @override
  void initState() {
    super.initState();
    _updateDateTimeDisplay();
    _memController.addListener(_calculateScore);
    _tajweedController.addListener(_calculateScore);
    _performanceController.addListener(_calculateScore);
  }

  @override
  void dispose() {
    _memController.dispose();
    _tajweedController.dispose();
    _performanceController.dispose();
    _notesController.dispose();
    _curriculumController.dispose();
    _dateTimeController.dispose();
    for (final controller in _hezbControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(studentTestsWithDetailsProvider(widget.studentId));
    ref.invalidate(studentTestsPageProvider(widget.studentId));
  }

  void _updateDateTimeDisplay() {
    _dateTimeController.text =
        '${_testDateTime.year}-${_testDateTime.month.toString().padLeft(2, '0')}-${_testDateTime.day.toString().padLeft(2, '0')} '
        '${_testDateTime.hour.toString().padLeft(2, '0')}:${_testDateTime.minute.toString().padLeft(2, '0')}';
  }

  void _calculateScore() {
    final mem = int.tryParse(_memController.text) ?? 0;
    final tajweed = int.tryParse(_tajweedController.text) ?? 0;
    final performance = int.tryParse(_performanceController.text) ?? 0;

    setState(() {
      _totalScore = mem + tajweed + performance;
      _grade = StudentTestGrades.calculate(_totalScore);
    });
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Future<void> _pickTestDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _testDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_testDateTime),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _testDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _updateDateTimeDisplay();
    });
  }

  String _buildHezbNumber() =>
      StudentTestHezb.join(_hezbControllers.map((c) => c.text).toList());

  void _resetForm() {
    _memController.text = '0';
    _tajweedController.text = '0';
    _performanceController.text = '0';
    _notesController.clear();
    _curriculumController.clear();
    for (final controller in _hezbControllers) {
      controller.clear();
    }
    setState(() {
      _testDateTime = DateTime.now();
      _updateDateTimeDisplay();
    });
    _calculateScore();
  }

  Future<void> _printCertificate(StudentTestDetail test) async {
    final period = await _pickTestPeriod();
    if (period == null || !mounted) return;

    setState(() => _printingTestId = test.testId);
    try {
      final html = await ref.read(testCertificateApiProvider).getCertificateHtml(
            test.testId,
            testPeriod: period,
          );
      await openCertificateForPrint(
        html,
        title: 'شهادة ${test.surahName}',
      );
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (_) {
      if (mounted) {
        _showMessage('تعذر تحميل الشهادة للطباعة', isError: true);
      }
    } finally {
      if (mounted) setState(() => _printingTestId = null);
    }
  }

  Future<String?> _pickTestPeriod() async {
    var selected = TestCertificatePeriods.periods.first;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'فترة الاختبار',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return DropdownButtonFormField<String>(
              value: selected,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: TestCertificatePeriods.periods
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p, style: AppFonts.cairo()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setDialogState(() => selected = value);
                }
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: AppFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text(
              'متابعة',
              style: AppFonts.cairo(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTest() async {
    final surahName = _curriculumController.text.trim();
    if (surahName.isEmpty) {
      _showMessage('يرجى إدخال مقرر الاختبار', isError: true);
      return;
    }

    final mem = int.tryParse(_memController.text) ?? 0;
    final tajweed = int.tryParse(_tajweedController.text) ?? 0;
    final performance = int.tryParse(_performanceController.text) ?? 0;

    if (mem < 0 ||
        mem > _memMax ||
        tajweed < 0 ||
        tajweed > _tajweedMax ||
        performance < 0 ||
        performance > _performanceMax) {
      _showMessage('الدرجات خارج النطاق المسموح', isError: true);
      return;
    }

    if (_totalScore > _totalMax) {
      _showMessage('المجموع لا يمكن أن يتجاوز $_totalMax', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notes = _notesController.text.trim();
      final message = await ref.read(studentTestsRepositoryProvider).createTest(
            widget.studentId,
            SaveStudentTestRequest(
              testDate: _testDateTime,
              surahName: surahName,
              hezbNumber: _buildHezbNumber(),
              memorizationScore: mem,
              tajweedScore: tajweed,
              revisionScore: performance,
              totalScore: _totalScore,
              grade: _grade,
              notes: notes.isEmpty ? null : notes,
            ),
          );

      _resetForm();
      _refresh();
      if (mounted) _showMessage(message);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (_) {
      if (mounted) _showMessage('تعذر حفظ الاختبار', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final testsAsync =
        ref.watch(studentTestsWithDetailsProvider(widget.studentId));
    final pageAsync = ref.watch(studentTestsPageProvider(widget.studentId));

    final displayName = widget.studentName ??
        pageAsync.maybeWhen(
          data: (page) => page.studentName.isNotEmpty ? page.studentName : null,
          orElse: () => null,
        ) ??
        'الطالب';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'اختبارات الطالب',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(displayName),
              const SizedBox(height: 24),
              _buildAddTestForm(),
              const SizedBox(height: 24),
              Text(
                'سجل الاختبارات',
                style: AppFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              testsAsync.when(
                data: (tests) => _buildTestsTable(tests),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildErrorState(
                  error is ApiException
                      ? error.message
                      : 'تعذر تحميل الاختبارات',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String studentName) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.assignment, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الطالب: $studentName',
                  style: AppFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.planLevelName != null &&
                    widget.planLevelName!.isNotEmpty)
                  Text(
                    widget.planLevelName!,
                    style: AppFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTestForm() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تسجيل اختبار جديد',
            style: AppFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'تاريخ ووقت الاختبار',
            hint: 'اختر التاريخ والوقت',
            controller: _dateTimeController,
            readOnly: true,
            onTap: _pickTestDateTime,
            suffix: const Icon(Icons.calendar_today, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'مقرر الاختبار',
            hint: 'أدخل اسم مقرر الاختبار',
            controller: _curriculumController,
          ),
          const SizedBox(height: 16),
          _buildHezbSection(),
          const SizedBox(height: 20),
          _buildScoresSection(),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'ملاحظات عامة',
            hint: 'أدخل ملاحظاتك هنا...',
            controller: _notesController,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'حفظ الاختبار',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _saveTest,
          ),
        ],
      ),
    );
  }

  Widget _buildHezbSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأحزاب',
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: StudentTestHezb.cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            return TextFormField(
              controller: _hezbControllers[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 2,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              style: AppFonts.cairo(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '${index + 1}',
                hintStyle: AppFonts.cairo(color: AppColors.textHint),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'درجات الاختبار',
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'الحفظ ($_memMax)',
          hint: '0',
          controller: _memController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'التجويد ($_tajweedMax)',
          hint: '0',
          controller: _tajweedController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Text(
            'أحكام النون الساكنة والتنوين ، النون والميم المشددتين',
            style: AppFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'الأداء ($_performanceMax)',
          hint: '0',
          controller: _performanceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Text(
            'تقييم نسبي على حسن الأداء وعدم الارتباك',
            style: AppFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTotalAndGrade(),
      ],
    );
  }

  Widget _buildTotalAndGrade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المجموع ($_totalMax)',
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_totalScore / $_totalMax',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'التقدير',
                    style: AppFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _grade,
                    style: AppFonts.cairo(
                      color: _getGradeColor(_grade),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.cairo(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _refresh,
            child: Text('إعادة المحاولة', style: AppFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'ممتاز':
        return AppColors.success;
      case 'جيد جدا':
      case 'جيد جداً':
        return AppColors.primary;
      case 'جيد':
        return AppColors.warning;
      case 'متوسط':
      case 'مقبول':
        return AppColors.textSecondary;
      default:
        return AppColors.error;
    }
  }

  Widget _buildTestsTable(List<StudentTestDetail> tests) {
    if (tests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'لا توجد اختبارات مسجلة',
          textAlign: TextAlign.center,
          style: AppFonts.cairo(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
              label: Text(
                'التاريخ',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'المقرر',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الأحزاب',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الحفظ',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'التجويد',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الأداء',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'المجموع',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'التقدير',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الشهادة',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: tests.map((test) {
            final grade = test.displayGrade;
            final hezbSummary = test.hezbCells
                .where((c) => c.isNotEmpty)
                .join('، ');
            return DataRow(
              cells: [
                DataCell(Text(test.displayDate, style: AppFonts.cairo())),
                DataCell(Text(test.surahName, style: AppFonts.cairo())),
                DataCell(Text(
                  hezbSummary.isEmpty ? '—' : hezbSummary,
                  style: AppFonts.cairo(fontSize: 12),
                )),
                DataCell(Text(
                  test.displayMemorization.toString(),
                  style: AppFonts.cairo(),
                )),
                DataCell(Text(
                  test.displayTajweed.toString(),
                  style: AppFonts.cairo(),
                )),
                DataCell(Text(
                  test.displayPerformance.toString(),
                  style: AppFonts.cairo(),
                )),
                DataCell(Text(
                  test.displayTotal.toString(),
                  style: AppFonts.cairo(),
                )),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getGradeColor(grade).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      grade,
                      style: AppFonts.cairo(
                        color: _getGradeColor(grade),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  _printingTestId == test.testId
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: 'طباعة الشهادة',
                          icon: const Icon(
                            Icons.print,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _printCertificate(test),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
