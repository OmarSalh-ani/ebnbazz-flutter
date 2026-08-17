import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_theme_extensions.dart';
import 'package:masged_parent_app/core/utils/app_permission_helper.dart';
import 'package:masged_parent_app/teacher_core/services/voice_command_service.dart';
import '../../../attendance/providers/attendance_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../models/dashboard_models.dart';
import '../../providers/dashboard_providers.dart';
import '../../screens/voice_command_examples_screen.dart';
import '../pulsing_mic_button.dart';

void showVoiceCommandBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const VoiceCommandBottomSheet(),
  );
}

class VoiceCommandBottomSheet extends ConsumerStatefulWidget {
  const VoiceCommandBottomSheet({super.key});

  @override
  ConsumerState<VoiceCommandBottomSheet> createState() =>
      _VoiceCommandBottomSheetState();
}

class _VoiceCommandBottomSheetState
    extends ConsumerState<VoiceCommandBottomSheet> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isVoiceListening = false;
  bool _isVoiceInitializing = true;
  bool _isVoiceProcessing = false;
  bool _isStartingListening = false;
  bool _stopRequested = false;
  String _arabicLocaleId = 'ar-SA';
  String _voiceSpokenText = '';
  String _voiceStatusMessage = 'جاري تهيئة الخدمة الصوتية...';
  bool _isVoiceError = false;
  bool _micNeedsSettings = false;
  bool _isVoiceSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  Future<void> _releaseMicrophone() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _speech.cancel();
    } catch (_) {}
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' && mounted && _stopRequested) {
      setState(() => _isVoiceListening = false);
    }
  }

  void _onSpeechError(dynamic error) {
    if (!mounted || !_stopRequested) return;
    setState(() {
      _isVoiceListening = false;
      _isVoiceError = true;
      _voiceStatusMessage =
          'عذرًا، لم يتم التقاط الصوت بوضوح. يرجى المحاولة مجددًا.';
    });
  }

  void _onSpeechResult(dynamic result) {
    if (!mounted || _stopRequested) return;
    setState(() {
      _voiceSpokenText = result.recognizedWords;
    });
    if (result.finalResult) {
      unawaited(_restartListeningIfNeeded());
    }
  }

  Future<void> _restartListeningIfNeeded() async {
    if (!mounted || _stopRequested || _isStartingListening) return;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted || _stopRequested || _speech.isListening) return;
    try {
      await _speech.listen(
        localeId: _arabicLocaleId,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 30),
        partialResults: true,
        onResult: _onSpeechResult,
      );
    } catch (_) {}
  }

  Future<void> _stopListeningAndProcess() async {
    if (_stopRequested) return;
    _stopRequested = true;
    await _releaseMicrophone();
    if (!mounted) return;
    setState(() => _isVoiceListening = false);
    await _processVoiceCommand(_voiceSpokenText);
  }

  @override
  void dispose() {
    unawaited(_releaseMicrophone());
    super.dispose();
  }

  Future<void> _processVoiceCommand(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _isVoiceError = true;
        _voiceStatusMessage = 'لم يتم سماع أي أمر. يرجى المحاولة مرة أخرى.';
      });
      return;
    }

    setState(() {
      _isVoiceProcessing = true;
      _isVoiceError = false;
      _isVoiceSuccess = false;
      _voiceStatusMessage = 'جاري تحليل الأمر...';
    });

    try {
      final parsed = VoiceCommandService.parseCommand(text);
      debugPrint('Parsed voice command result: $parsed');

      if (parsed.type == VoiceCommandType.unrecognized) {
        setState(() {
          _isVoiceProcessing = false;
          _isVoiceError = true;
          _voiceStatusMessage =
              'عذرًا، لم يتم التعرف على الأمر. حاول مرة أخرى بصياغة أوضح.';
        });
        return;
      }

      setState(() {
        _isVoiceProcessing = false;
        _voiceStatusMessage = 'راجع الأمر ثم أكّد التنفيذ';
      });

      final confirmed = await _showVoiceCommandConfirmDialog(
        spokenText: text,
        parsed: parsed,
      );
      if (!confirmed || !mounted) {
        setState(() {
          _voiceStatusMessage = 'تم إلغاء الأمر. يمكنك المحاولة مرة أخرى.';
        });
        return;
      }

      List<StudentListItem>? absentStudents;

      if (parsed.type == VoiceCommandType.attendanceExcept) {
        final pageState = ref.read(dashboardPageProvider);
        final students = pageState.valueOrNull?.students ?? [];
        absentStudents = await _resolveAbsentStudentsForVoice(
          parsed: parsed,
          students: students,
        );
        if (!mounted) return;
        if (absentStudents == null) {
          setState(() {
            _voiceStatusMessage = 'لم يتم تحديد الغائبين. يمكنك المحاولة مرة أخرى.';
          });
          return;
        }
      }

      await _executeConfirmedVoiceCommand(
        parsed: parsed,
        absentStudents: absentStudents,
      );
    } catch (e) {
      setState(() {
        _isVoiceProcessing = false;
        _isVoiceError = true;
        _voiceStatusMessage = e.toString().replaceFirst('Exception:', '').trim();
      });
    }
  }

  Future<bool> _showVoiceCommandConfirmDialog({
    required String spokenText,
    required VoiceCommandResult parsed,
  }) async {
    final pageState = ref.read(dashboardPageProvider);
    final studentCount = pageState.valueOrNull?.students.length ?? 0;
    final description = VoiceCommandService.describeCommand(
      parsed,
      studentCount: studentCount,
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تأكيد الأمر الصوتي',
          textAlign: TextAlign.right,
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: context.appPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'هل تريد تنفيذ الأمر التالي؟',
                textAlign: TextAlign.right,
                style: AppFonts.cairo(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.appPrimary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  description,
                  textAlign: TextAlign.right,
                  style: AppFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ما قلته:',
                textAlign: TextAlign.right,
                style: AppFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                spokenText,
                textAlign: TextAlign.right,
                style: AppFonts.cairo(
                  fontSize: 14,
                  color: context.appPrimary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'إلغاء',
              style: AppFonts.cairo(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: context.appPrimary),
            child: Text(
              'تأكيد وتنفيذ',
              style: AppFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<List<StudentListItem>?> _resolveAbsentStudentsForVoice({
    required VoiceCommandResult parsed,
    required List<StudentListItem> students,
  }) async {
    if (students.isEmpty) {
      throw Exception('لا يوجد طلاب في الحلقة الحالية.');
    }

    final resolution = VoiceCommandService.resolveExcludedStudents(
      students,
      namesBlob: parsed.excludedNamesBlob ?? '',
      phrases: parsed.excludedNamePhrases,
    );

    if (!resolution.needsManualSelection && resolution.excludedStudents.isNotEmpty) {
      return resolution.excludedStudents;
    }

    final phrasesForSuggestions = resolution.unmatchedPhrases.isNotEmpty
        ? resolution.unmatchedPhrases
        : parsed.excludedNamePhrases;

    var suggestions = VoiceCommandService.suggestAbsentStudents(
      students,
      phrasesForSuggestions,
      resolution.excludedStudents,
    );

    if (suggestions.isEmpty) {
      suggestions = students
          .map(
            (s) => StudentMatchCandidate(
              student: s,
              score: 0,
              isExact: false,
            ),
          )
          .toList();
    }

    if (!mounted) return null;
    return _showVoiceAbsentStudentsPickerDialog(
      preselected: resolution.excludedStudents,
      candidates: suggestions,
      unmatchedPhrases: phrasesForSuggestions,
      spokenBlob: parsed.excludedNamesBlob ?? '',
    );
  }

  Future<List<StudentListItem>?> _showVoiceAbsentStudentsPickerDialog({
    required List<StudentListItem> preselected,
    required List<StudentMatchCandidate> candidates,
    required List<String> unmatchedPhrases,
    required String spokenBlob,
  }) async {
    final selectedIds = {for (final s in preselected) s.id};

    return showDialog<List<StudentListItem>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void toggleStudent(int id) {
              setDialogState(() {
                if (selectedIds.contains(id)) {
                  selectedIds.remove(id);
                } else {
                  selectedIds.add(id);
                }
              });
            }

            final selectedStudents = candidates
                .map((c) => c.student)
                .where((s) => selectedIds.contains(s.id))
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'الطلاب الغائبين اليوم',
                textAlign: TextAlign.right,
                style: AppFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: context.appPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      unmatchedPhrases.isNotEmpty
                          ? 'لم نتأكد من بعض الأسماء. اختر الطلاب الغائبين (لن يُحضَّروا):'
                          : 'اختر الطلاب الغائبين اليوم (لن يُحضَّروا):',
                      textAlign: TextAlign.right,
                      style: AppFonts.cairo(color: AppColors.textSecondary),
                    ),
                    if (spokenBlob.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'في الأمر: "$spokenBlob"',
                        textAlign: TextAlign.right,
                        style: AppFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.appPrimary,
                        ),
                      ),
                    ],
                    if (unmatchedPhrases.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'أسماء غير واضحة: ${unmatchedPhrases.join('، ')}',
                        textAlign: TextAlign.right,
                        style: AppFonts.cairo(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: candidates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final student = candidates[index].student;
                          final isSelected = selectedIds.contains(student.id);
                          return InkWell(
                            onTap: () => toggleStudent(student.id),
                            borderRadius: BorderRadius.circular(14),
                            child: _buildVoiceStudentCard(
                              student,
                              highlighted: isSelected,
                              trailing: Icon(
                                isSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: isSelected
                                    ? context.appPrimary
                                    : Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'إلغاء',
                    style: AppFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: selectedStudents.isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, selectedStudents),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appPrimary,
                  ),
                  child: Text(
                    'تأكيد (${selectedStudents.length} غائب)',
                    style: AppFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildVoiceStudentCard(
    StudentListItem student, {
    bool highlighted = false,
    Widget? trailing,
  }) {
    final primary = context.appPrimary;
    final isMrkz = ref.watch(teacherIsMrkzProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? primary.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? primary.withValues(alpha: 0.35)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: primary.withValues(alpha: 0.12),
            backgroundImage: student.imageUrl != null
                ? NetworkImage(student.imageUrl!)
                : null,
            child: student.imageUrl == null
                ? Icon(Icons.person, color: primary, size: 32)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: AppFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  student.listSubtitle(isMrkz: isMrkz),
                  style: AppFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else if (highlighted)
            Icon(Icons.check_circle, color: primary, size: 22),
        ],
      ),
    );
  }

  Future<void> _executeConfirmedVoiceCommand({
    required VoiceCommandResult parsed,
    List<StudentListItem>? absentStudents,
  }) async {
    setState(() {
      _isVoiceProcessing = true;
      _isVoiceError = false;
      _voiceStatusMessage = 'جاري تنفيذ الأمر...';
    });

    if (parsed.type == VoiceCommandType.attendance) {
      final pageState = ref.read(dashboardPageProvider);
      final students = pageState.valueOrNull?.students ?? [];

      if (students.isEmpty) {
        throw Exception('لا يوجد طلاب في الحلقة الحالية لتسجيل حضورهم.');
      }

      final studentIds = students.map((s) => s.id).toList();
      setState(() {
        _voiceStatusMessage =
            'جاري تحضير جميع الطلاب (${studentIds.length})...';
      });

      final resultMsg = await ref
          .read(attendanceRepositoryProvider)
          .markAllAttendance(studentIds);

      await ref.read(dashboardPageProvider.notifier).refresh();

      setState(() {
        _isVoiceProcessing = false;
        _isVoiceSuccess = true;
        _voiceStatusMessage = resultMsg.isNotEmpty
            ? resultMsg
            : 'تم تحضير جميع الطلاب بنجاح!';
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    } else if (parsed.type == VoiceCommandType.attendanceExcept) {
      final pageState = ref.read(dashboardPageProvider);
      final students = pageState.valueOrNull?.students ?? [];

      if (students.isEmpty) {
        throw Exception('لا يوجد طلاب في الحلقة الحالية لتسجيل حضورهم.');
      }

      final absentIds = (absentStudents ?? []).map((s) => s.id).toSet();
      final presentIds = students
          .where((s) => !absentIds.contains(s.id))
          .map((s) => s.id)
          .toList();

      if (presentIds.isEmpty) {
        throw Exception('لا يوجد طلاب للتحضير بعد استثناء الغائبين.');
      }

      setState(() {
        _voiceStatusMessage =
            'جاري تحضير ${presentIds.length} طالب (استثناء ${absentIds.length} غائب)...';
      });

      final resultMsg = await ref
          .read(attendanceRepositoryProvider)
          .markAllAttendance(presentIds);

      await ref.read(dashboardPageProvider.notifier).refresh();

      setState(() {
        _isVoiceProcessing = false;
        _isVoiceSuccess = true;
        _voiceStatusMessage = resultMsg.isNotEmpty
            ? resultMsg
            : 'تم تحضير ${presentIds.length} طالب (استثناء ${absentIds.length} غائب)!';
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    } else if (parsed.type == VoiceCommandType.departure) {
      final pageState = ref.read(dashboardPageProvider);
      final students = pageState.valueOrNull?.students ?? [];

      if (students.isEmpty) {
        throw Exception('لا يوجد طلاب في الحلقة الحالية لتسجيل انصرافهم.');
      }

      final studentIds = students.map((s) => s.id).toList();
      setState(() {
        _voiceStatusMessage =
            'جاري تسجيل انصراف جميع الطلاب (${studentIds.length})...';
      });

      final resultMsg = await ref
          .read(attendanceRepositoryProvider)
          .markAllDeparture(studentIds);

      await ref.read(dashboardPageProvider.notifier).refresh();

      setState(() {
        _isVoiceProcessing = false;
        _isVoiceSuccess = true;
        _voiceStatusMessage = resultMsg.isNotEmpty
            ? resultMsg
            : 'تم تسجيل انصراف جميع الطلاب بنجاح!';
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _startListening() async {
    if (!mounted || _isStartingListening) return;

    _isStartingListening = true;
    _stopRequested = false;
    try {
      setState(() {
        _isVoiceInitializing = true;
        _isVoiceError = false;
        _micNeedsSettings = false;
        _isVoiceSuccess = false;
        _voiceSpokenText = '';
        _voiceStatusMessage = 'جاري تهيئة الميكروفون...';
      });

      final micStatus =
          await AppPermissionHelper.requestRuntime(Permission.microphone);
      if (!mounted) return;

      if (!AppPermissionHelper.canUse(micStatus)) {
        setState(() {
          _isVoiceInitializing = false;
          _isVoiceError = true;
          _micNeedsSettings = AppPermissionHelper.needsSettings(micStatus);
          _voiceStatusMessage = _micNeedsSettings
              ? 'تم رفض الميكروفون سابقاً. فعّله من إعدادات التطبيق لاستخدام الأوامر الصوتية.'
              : 'يتطلب المساعد الصوتي إذن الميكروفون. سيظهر طلب النظام عند المحاولة.';
        });
        return;
      }

      final available = _speech.isAvailable
          ? true
          : await _speech
              .initialize(
                onStatus: _onSpeechStatus,
                onError: _onSpeechError,
              )
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => false,
              );

      if (!mounted) return;

      if (!available) {
        setState(() {
          _isVoiceInitializing = false;
          _isVoiceError = true;
          _voiceStatusMessage = 'الخدمة الصوتية غير متاحة على هذا الجهاز.';
        });
        return;
      }

      final locales = await _speech.locales().timeout(
            const Duration(seconds: 5),
            onTimeout: () => <stt.LocaleName>[],
          );
      if (!mounted) return;

      var arabicLocale = stt.LocaleName('ar-SA', 'Arabic');
      for (final locale in locales) {
        if (locale.localeId.startsWith('ar')) {
          arabicLocale = locale;
          break;
        }
      }
      _arabicLocaleId = arabicLocale.localeId;

      setState(() {
        _isVoiceInitializing = false;
        _isVoiceListening = true;
        _voiceStatusMessage =
            'تحدث الآن، وعند الانتهاء اضغط زر الإيقاف لتحليل الأمر.';
      });

      await _speech.listen(
        localeId: _arabicLocaleId,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 30),
        partialResults: true,
        onResult: _onSpeechResult,
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isVoiceInitializing = false;
        _isVoiceListening = false;
        _isVoiceError = true;
        _voiceStatusMessage =
            'انتهت مهلة تهيئة المايكروفون. تأكد من تثبيت خدمة Google Speech ثم حاول مجددًا.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVoiceInitializing = false;
        _isVoiceListening = false;
        _isVoiceError = true;
        _voiceStatusMessage = 'فشل تشغيل المايكروفون: $e';
      });
    } finally {
      _isStartingListening = false;
      if (mounted && _isVoiceInitializing) {
        setState(() => _isVoiceInitializing = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  if (_isVoiceListening) {
                    await _releaseMicrophone();
                    if (!mounted) return;
                    setState(() => _isVoiceListening = false);
                  }
                  if (!context.mounted) return;
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const VoiceCommandExamplesScreen(),
                    ),
                  );
                },
                tooltip: 'أمثلة الأوامر الصوتية',
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: context.appPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  'المساعد الصوتي الذكي',
                  textAlign: TextAlign.center,
                  style: AppFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.appPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: _isVoiceInitializing
                ? const SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : _isVoiceProcessing
                    ? SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(context.appPrimary),
                        ),
                      )
                    : _isVoiceSuccess
                        ? Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 40,
                            ),
                          )
                        : PulsingMicButton(
                            isListening: _isVoiceListening,
                            onTap: () async {
                              if (_isVoiceListening) {
                                await _stopListeningAndProcess();
                              } else if (!_isVoiceProcessing) {
                                await _startListening();
                              }
                            },
                          ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isVoiceError
                  ? Colors.red.shade50
                  : _isVoiceSuccess
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isVoiceError
                    ? Colors.red.shade100
                    : _isVoiceSuccess
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _voiceStatusMessage,
                  textAlign: TextAlign.center,
                  style: AppFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isVoiceError
                        ? Colors.red.shade700
                        : _isVoiceSuccess
                            ? Colors.green.shade700
                            : AppColors.textSecondary,
                  ),
                ),
                if (_voiceSpokenText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    _voiceSpokenText,
                    textAlign: TextAlign.center,
                    style: AppFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.appPrimary,
                    ),
                  ),
                ],
                if (_isVoiceError && _micNeedsSettings) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: openAppSettings,
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(
                      'فتح إعدادات التطبيق',
                      style: AppFonts.cairo(fontWeight: FontWeight.bold),
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
}
