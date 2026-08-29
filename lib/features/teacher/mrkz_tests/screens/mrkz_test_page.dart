import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/core/utils/exported_file_saver.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import 'package:masged_parent_app/shared/widgets/custom_text_field.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/mrkz_test_models.dart';
import '../providers/mrkz_tests_providers.dart';

class MrkzTestPage extends ConsumerStatefulWidget {
  const MrkzTestPage({
    super.key,
    required this.studentId,
    this.studentName,
  });

  final int studentId;
  final String? studentName;

  @override
  ConsumerState<MrkzTestPage> createState() => _MrkzTestPageState();
}

class _MatnRowControllers {
  _MatnRowControllers()
      : name = TextEditingController(),
        score = TextEditingController();

  final TextEditingController name;
  final TextEditingController score;

  void dispose() {
    name.dispose();
    score.dispose();
  }
}

class _MrkzTestPageState extends ConsumerState<MrkzTestPage> {
  final _rows = <_MatnRowControllers>[_MatnRowControllers()];
  bool _isSaving = false;
  int? _downloadingTestId;

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(mrkzTestsPageProvider(widget.studentId));
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  void _addRow() {
    setState(() => _rows.add(_MatnRowControllers()));
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows.removeAt(index).dispose();
    });
  }

  void _resetForm() {
    for (final row in _rows) {
      row.dispose();
    }
    setState(() {
      _rows
        ..clear()
        ..add(_MatnRowControllers());
    });
  }

  List<MrkzTestItem>? _collectItems() {
    final items = <MrkzTestItem>[];
    for (final row in _rows) {
      final name = row.name.text.trim();
      final scoreText = row.score.text.trim();
      if (name.isEmpty && scoreText.isEmpty) continue;

      if (name.isEmpty) {
        _showMessage('يرجى إدخال اسم المتن', isError: true);
        return null;
      }

      final score = double.tryParse(scoreText);
      if (score == null) {
        _showMessage('يرجى إدخال درجة صحيحة لـ "$name"', isError: true);
        return null;
      }
      if (score < 0 || score > 100) {
        _showMessage('الدرجة يجب أن تكون بين 0 و 100', isError: true);
        return null;
      }

      items.add(MrkzTestItem(mtnName: name, score: score));
    }

    if (items.isEmpty) {
      _showMessage('أضف متناً واحداً على الأقل مع درجته', isError: true);
      return null;
    }

    return items;
  }

  Future<void> _saveTest() async {
    final items = _collectItems();
    if (items == null) return;

    setState(() => _isSaving = true);
    try {
      final message = await ref.read(mrkzTestsApiProvider).createTest(
            widget.studentId,
            SaveMrkzTestRequest(items: items),
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

  Future<void> _downloadCertificate(MrkzTestRecord test) async {
    setState(() => _downloadingTestId = test.testId);
    try {
      final pdf = await ref.read(mrkzTestsApiProvider).getCertificatePdf(test.testId);
      await saveExportedFile(pdf.bytes, pdf.fileName);
      if (mounted) {
        _showMessage('تم حفظ الملف في مجلد التنزيلات');
      }
    } catch (error) {
      final opened = await _openCertificatePdfInBrowser(test.testId);
      if (!mounted) return;
      if (opened) {
        _showMessage('تعذر حفظ الملف، تم فتح الشهادة في المتصفح');
      } else if (error is ApiException) {
        _showMessage(error.message, isError: true);
      } else {
        _showMessage('تعذر تحميل الشهادة', isError: true);
      }
    } finally {
      if (mounted) setState(() => _downloadingTestId = null);
    }
  }

  Future<bool> _openCertificatePdfInBrowser(int testId) async {
    try {
      final token = await ref.read(authStorageProvider).getToken();
      final uri = ref.read(mrkzTestsApiProvider).certificatePdfUri(
            testId: testId,
            accessToken: token,
          );
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'ممتاز':
        return AppColors.success;
      case 'جيد جدا':
      case 'جيد جداً':
        return AppColors.mrkzPrimary;
      case 'جيد':
        return AppColors.warning;
      case 'متوسط':
      case 'مقبول':
        return AppColors.textSecondary;
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(mrkzTestsPageProvider(widget.studentId));
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
              pageAsync.when(
                data: (page) => _buildTestsTable(page.tests),
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
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.mrkzPrimaryLight,
            child: Icon(Icons.assignment, color: AppColors.mrkzPrimary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'الطالب: $studentName',
              style: AppFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
            color: Colors.black.withValues(alpha: 0.02),
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
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildMatnRow(i),
          ],
          const SizedBox(height: 16),
          CustomButton(
            text: 'إضافة متن',
            icon: Icons.add,
            isOutlined: true,
            height: 46,
            onPressed: _addRow,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'حفظ',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _saveTest,
          ),
        ],
      ),
    );
  }

  Widget _buildMatnRow(int index) {
    final row = _rows[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'متن ${index + 1}',
                style: AppFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (_rows.length > 1)
              IconButton(
                tooltip: 'حذف المتن',
                visualDensity: VisualDensity.compact,
                onPressed: () => _removeRow(index),
                icon: const Icon(Icons.close, color: AppColors.error, size: 20),
              ),
          ],
        ),
        CustomTextField(
          label: 'اسم المتن',
          hint: 'أدخل اسم المتن',
          controller: row.name,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'الدرجة',
          hint: '0 - 100',
          controller: row.score,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
          ],
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

  Widget _buildTestsTable(List<MrkzTestRecord> tests) {
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
            color: Colors.black.withValues(alpha: 0.02),
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
              label: Text('التاريخ', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('المتون', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('المتوسط', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('التقدير', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('الشهادة', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: tests.map((test) {
            final grade = test.grade.isEmpty
                ? MrkzTestGrades.calculate(test.averageScore)
                : test.grade;
            return DataRow(
              cells: [
                DataCell(Text(test.displayDate, style: AppFonts.cairo())),
                DataCell(SizedBox(
                  width: 180,
                  child: Text(
                    test.mutoonSummary,
                    style: AppFonts.cairo(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(Text(test.displayAverage, style: AppFonts.cairo())),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gradeColor(grade).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      grade,
                      style: AppFonts.cairo(
                        color: _gradeColor(grade),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  _downloadingTestId == test.testId
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: 'طباعة الشهادة',
                          icon: const Icon(
                            Icons.print_outlined,
                            color: AppColors.mrkzPrimary,
                          ),
                          onPressed: () => _downloadCertificate(test),
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
