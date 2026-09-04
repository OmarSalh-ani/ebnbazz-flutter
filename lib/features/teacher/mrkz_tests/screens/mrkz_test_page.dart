import 'package:flutter/material.dart';
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

class _MrkzTestPageState extends ConsumerState<MrkzTestPage> {
  MrkzTestDefinitionOption? _selectedDefinition;
  int _mistakeCount = 0;
  final _notesController = TextEditingController();
  final _totalScoreController = TextEditingController();
  final _finalScoreController = TextEditingController();
  bool _isSaving = false;
  int? _downloadingResultId;

  @override
  void dispose() {
    _notesController.dispose();
    _totalScoreController.dispose();
    _finalScoreController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(mrkzTestDefinitionsProvider(widget.studentId));
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

  void _resetForm() {
    setState(() {
      _selectedDefinition = null;
      _mistakeCount = 0;
      _notesController.clear();
      _totalScoreController.clear();
      _finalScoreController.clear();
    });
  }

  void _onDefinitionSelected(MrkzTestDefinitionOption? definition) {
    setState(() {
      _selectedDefinition = definition;
      _mistakeCount = 0;
      _totalScoreController.text =
          definition == null ? '' : _formatScore(definition.totalScore);
      _updateFinalScoreField();
    });
  }

  void _incrementMistake() {
    setState(() {
      _mistakeCount++;
      _updateFinalScoreField();
    });
  }

  void _updateFinalScoreField() {
    final score = _finalScore;
    _finalScoreController.text = score == null ? '' : _formatScore(score);
  }

  double? get _finalScore {
    final definition = _selectedDefinition;
    if (definition == null) return null;
    return calculateMrkzFinalScore(
      totalScore: definition.totalScore,
      mistakeCount: _mistakeCount,
      errorWeight: definition.errorWeight,
    );
  }

  Future<void> _saveTest() async {
    final definition = _selectedDefinition;
    if (definition == null) {
      _showMessage('يرجى اختيار المتن', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final message = await ref.read(mrkzTestsApiProvider).createTest(
            widget.studentId,
            SaveMrkzTestResultRequest(
              testDefinitionId: definition.id,
              mistakeCount: _mistakeCount,
              notes: _notesController.text,
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

  Future<void> _downloadCertificate(MrkzTestResultRecord test) async {
    setState(() => _downloadingResultId = test.resultId);
    try {
      final pdf = await ref.read(mrkzTestsApiProvider).getCertificatePdf(test.resultId);
      await saveExportedFile(pdf.bytes, pdf.fileName);
      if (mounted) {
        _showMessage('اختر «فتح» أو «حفظ» من قائمة المشاركة');
      }
    } catch (error) {
      final opened = await _openCertificatePdfInBrowser(test.resultId);
      if (!mounted) return;
      if (opened) {
        _showMessage('تعذر حفظ الملف، تم فتح الشهادة في المتصفح');
      } else if (error is ApiException) {
        _showMessage(error.message, isError: true);
      } else {
        _showMessage('تعذر تحميل الشهادة', isError: true);
      }
    } finally {
      if (mounted) setState(() => _downloadingResultId = null);
    }
  }

  Future<bool> _openCertificatePdfInBrowser(int resultId) async {
    try {
      final token = await ref.read(authStorageProvider).getToken();
      final uri = ref.read(mrkzTestsApiProvider).certificatePdfUri(
            resultId: resultId,
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
    final definitionsAsync = ref.watch(mrkzTestDefinitionsProvider(widget.studentId));
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
              definitionsAsync.when(
                data: (definitions) => _buildEntryForm(definitions),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildErrorState(
                  error is ApiException
                      ? error.message
                      : 'تعذر تحميل قائمة المتون',
                ),
              ),
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

  Widget _buildEntryForm(List<MrkzTestDefinitionOption> definitions) {
    if (definitions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'لا توجد اختبارات مفعّلة مخصصة لك',
          textAlign: TextAlign.center,
          style: AppFonts.cairo(color: AppColors.textSecondary),
        ),
      );
    }

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
          Autocomplete<MrkzTestDefinitionOption>(
            displayStringForOption: (option) => option.mtnName,
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) return definitions;
              return definitions
                  .where((item) => item.mtnName.toLowerCase().contains(query));
            },
            onSelected: _onDefinitionSelected,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (_selectedDefinition != null &&
                  controller.text != _selectedDefinition!.mtnName) {
                controller.text = _selectedDefinition!.mtnName;
              }
              return CustomTextField(
                label: 'المتن',
                hint: 'ابحث واختر المتن',
                controller: controller,
                focusNode: focusNode,
                onChanged: (_) {
                  if (_selectedDefinition != null) {
                    setState(() => _selectedDefinition = null);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'الدرجة الكلية',
            hint: '—',
            controller: _totalScoreController,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: _selectedDefinition == null
                ? 'خطأ'
                : 'خطأ (وزن: ${_formatScore(_selectedDefinition!.errorWeight)})',
            icon: Icons.close,
            isOutlined: true,
            height: 46,
            onPressed: _selectedDefinition == null ? null : _incrementMistake,
          ),
          const SizedBox(height: 8),
          Text(
            'عدد الأخطاء: $_mistakeCount',
            style: AppFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'النتيجة النهائية',
            hint: '—',
            controller: _finalScoreController,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'ملاحظات',
            hint: 'ملاحظات اختيارية',
            controller: _notesController,
            maxLines: 3,
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

  Widget _buildTestsTable(List<MrkzTestResultRecord> tests) {
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
              label: Text('المتن', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('الأخطاء', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('النتيجة', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('التقدير', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('ملاحظات', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('الشهادة', style: AppFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: tests.map((test) {
            return DataRow(
              cells: [
                DataCell(Text(test.displayDate, style: AppFonts.cairo())),
                DataCell(Text(test.mtnName, style: AppFonts.cairo(fontSize: 12))),
                DataCell(Text('${test.mistakeCount}', style: AppFonts.cairo())),
                DataCell(Text(test.displayFinalScore, style: AppFonts.cairo())),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gradeColor(test.grade).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      test.grade,
                      style: AppFonts.cairo(
                        color: _gradeColor(test.grade),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(SizedBox(
                  width: 140,
                  child: Text(
                    test.notes?.isNotEmpty == true ? test.notes! : '—',
                    style: AppFonts.cairo(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(
                  _downloadingResultId == test.resultId
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

  String _formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.round().toString();
    }
    return score.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}
