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
import '../widgets/mrkz_test_definition_picker_sheet.dart';

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

  void _decrementMistake() {
    if (_mistakeCount <= 0) return;
    setState(() {
      _mistakeCount--;
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

  int get _deductedPoints {
    final definition = _selectedDefinition;
    if (definition == null) return 0;
    return (_mistakeCount * definition.errorWeight).round();
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
              const SizedBox(height: 20),
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
              Row(
                children: [
                  Text(
                    'سجل الاختبارات',
                    style: AppFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  pageAsync.maybeWhen(
                    data: (page) => Text(
                      '${page.tests.length} اختبار',
                      style: AppFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              pageAsync.when(
                data: (page) => _buildHistoryList(page.tests),
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
        gradient: LinearGradient(
          colors: [
            AppColors.mrkzPrimary.withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mrkzPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.mrkzPrimary.withValues(alpha: 0.12),
            child: const Icon(Icons.assignment, color: AppColors.mrkzPrimary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: AppFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تسجيل ومتابعة اختبارات المركز',
                  style: AppFonts.cairo(
                    fontSize: 13,
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

  Future<void> _pickDefinition(List<MrkzTestDefinitionOption> definitions) async {
    final picked = await showMrkzTestDefinitionPickerSheet(
      context: context,
      definitions: definitions,
      selected: _selectedDefinition,
    );
    if (picked != null) {
      _onDefinitionSelected(picked);
    }
  }

  Widget _buildMtnPicker(List<MrkzTestDefinitionOption> definitions) {
    final selectedName = _selectedDefinition?.mtnName;
    final hasSelection = selectedName?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المتن',
          style: AppFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _pickDefinition(definitions),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasSelection
                      ? AppColors.mrkzPrimary.withValues(alpha: 0.35)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasSelection ? selectedName! : 'اضغط لاختيار المتن',
                      style: AppFonts.cairo(
                        fontSize: 15,
                        fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                        color: hasSelection
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: hasSelection ? AppColors.mrkzPrimary : AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryForm(List<MrkzTestDefinitionOption> definitions) {
    if (definitions.isEmpty) {
      return _buildInfoCard(
        icon: Icons.info_outline,
        message: 'لا توجد اختبارات مفعّلة مخصصة لك',
      );
    }

    final definition = _selectedDefinition;
    final hasAdminNotes = definition?.adminNotes?.trim().isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.mrkzPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note, color: AppColors.mrkzPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'تسجيل اختبار جديد',
                style: AppFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMtnPicker(definitions),
          if (hasAdminNotes) ...[
            const SizedBox(height: 16),
            _buildAdminNotesCard(definition!.adminNotes!.trim()),
          ],
          if (definition != null) ...[
            const SizedBox(height: 20),
            _buildScoreSummary(definition),
            const SizedBox(height: 20),
            _buildMistakeControls(definition),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'النتيجة النهائية',
              hint: '—',
              controller: _finalScoreController,
              readOnly: true,
            ),
          ] else ...[
            const SizedBox(height: 16),
            CustomTextField(
              label: 'الدرجة الكلية',
              hint: 'اختر المتن أولاً',
              controller: _totalScoreController,
              readOnly: true,
            ),
          ],
          const SizedBox(height: 16),
          CustomTextField(
            label: 'ملاحظات المعلم',
            hint: 'أضف ملاحظاتك عن أداء الطالب (اختياري)',
            controller: _notesController,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'حفظ الاختبار',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: _isSaving || definition == null ? null : _saveTest,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNotesCard(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mrkzPrimaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mrkzPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined,
                  size: 18, color: AppColors.mrkzPrimary),
              const SizedBox(width: 8),
              Text(
                'ملاحظات الإدارة',
                style: AppFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mrkzPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: AppFonts.cairo(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSummary(MrkzTestDefinitionOption definition) {
    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            label: 'الدرجة الكلية',
            value: _formatScore(definition.totalScore),
            icon: Icons.star_outline,
            color: AppColors.mrkzPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatChip(
            label: 'وزن الخطأ',
            value: _formatScore(definition.errorWeight),
            icon: Icons.remove_circle_outline,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatChip(
            label: 'المخصوم',
            value: '$_deductedPoints',
            icon: Icons.trending_down,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeControls(MrkzTestDefinitionOption definition) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            'تسجيل الأخطاء',
            style: AppFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'كل خطأ يخصم ${_formatScore(definition.errorWeight)} درجة',
            style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMistakeActionButton(
                icon: Icons.remove,
                label: 'استرجاع',
                color: AppColors.textSecondary,
                enabled: _mistakeCount > 0,
                onTap: _decrementMistake,
              ),
              const SizedBox(width: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _mistakeCount > 0
                      ? AppColors.error.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  border: Border.all(
                    color: _mistakeCount > 0
                        ? AppColors.error.withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_mistakeCount',
                  style: AppFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _mistakeCount > 0 ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _buildMistakeActionButton(
                icon: Icons.add,
                label: 'خطأ',
                color: AppColors.error,
                enabled: true,
                onTap: _incrementMistake,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.cairo(color: AppColors.textSecondary),
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

  Widget _buildHistoryList(List<MrkzTestResultRecord> tests) {
    if (tests.isEmpty) {
      return _buildInfoCard(
        icon: Icons.history,
        message: 'لا توجد اختبارات مسجلة بعد',
      );
    }

    return Column(
      children: tests.map(_buildHistoryCard).toList(),
    );
  }

  Widget _buildHistoryCard(MrkzTestResultRecord test) {
    final isDownloading = _downloadingResultId == test.resultId;
    final teacherNotes = test.notes?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.mtnName,
                      style: AppFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      test.displayDate,
                      style: AppFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _gradeColor(test.grade).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  test.grade,
                  style: AppFonts.cairo(
                    color: _gradeColor(test.grade),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildHistoryMeta('الأخطاء', '${test.mistakeCount}'),
              const SizedBox(width: 16),
              _buildHistoryMeta('النتيجة', test.displayFinalScore),
              const SizedBox(width: 16),
              _buildHistoryMeta('من', _formatScore(test.totalScore)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظات المعلم',
                  style: AppFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  teacherNotes?.isNotEmpty == true ? teacherNotes! : 'لا توجد ملاحظات',
                  style: AppFonts.cairo(
                    fontSize: 14,
                    color: teacherNotes?.isNotEmpty == true
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isDownloading ? null : () => _downloadCertificate(test),
              icon: isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 20),
              label: Text(
                isDownloading ? 'جاري التحميل...' : 'تحميل الشهادة',
                style: AppFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mrkzPrimary,
                side: BorderSide(color: AppColors.mrkzPrimary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryMeta(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
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
