import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';

import '../models/student_plan_models.dart';
import '../providers/student_plan_providers.dart';

class PlanExpiredSheet extends ConsumerStatefulWidget {
  const PlanExpiredSheet({
    super.key,
    required this.studentId,
    required this.detail,
    required this.onResolved,
    this.onClosed,
    this.onMessage,
  });

  final int studentId;
  final StudentPlanDetail detail;
  final VoidCallback onResolved;
  final VoidCallback? onClosed;
  final void Function(String message, {bool isError})? onMessage;

  static Future<void> show(
    BuildContext context, {
    required int studentId,
    required StudentPlanDetail detail,
    required VoidCallback onResolved,
    VoidCallback? onClosed,
    void Function(String message, {bool isError})? onMessage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: PlanExpiredSheet(
          studentId: studentId,
          detail: detail,
          onResolved: onResolved,
          onClosed: onClosed,
          onMessage: onMessage,
        ),
      ),
    );
  }

  @override
  ConsumerState<PlanExpiredSheet> createState() => _PlanExpiredSheetState();
}

class _PlanExpiredSheetState extends ConsumerState<PlanExpiredSheet> {
  bool _isExtending = false;
  bool _isClosing = false;

  DateTime get _minExtendDate {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dayAfterEnd = widget.detail.planToDate.add(const Duration(days: 1));
    return tomorrow.isAfter(dayAfterEnd) ? tomorrow : dayAfterEnd;
  }

  Future<void> _extendPlan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _minExtendDate,
      firstDate: _minExtendDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'تاريخ نهاية الخطة الجديد',
    );
    if (picked == null || !mounted) return;

    setState(() => _isExtending = true);
    try {
      await ref.read(studentPlanRepositoryProvider).updatePlanDates(
            widget.studentId,
            widget.detail.planId,
            planStartDate: widget.detail.planFromDate,
            planEndDate: picked,
          );
      if (!mounted) return;
      widget.onMessage?.call('تم تمديد الخطة بنجاح');
      widget.onResolved();
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      widget.onMessage?.call(e.message, isError: true);
    } catch (_) {
      widget.onMessage?.call('تعذر تمديد الخطة', isError: true);
    } finally {
      if (mounted) setState(() => _isExtending = false);
    }
  }

  Future<void> _confirmClosePlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إنهاء الخطة',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'سيتم حذف السور غير المكتملة وإغلاق الخطة. السور المكتملة (تم الحفظ / تم المراجعة) '
          'ستُحفظ في الأرشيف. هل تريد المتابعة؟',
          style: AppFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: AppFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'إنهاء الخطة',
              style: AppFonts.cairo(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClosing = true);
    try {
      await ref.read(studentPlanRepositoryProvider).closeExpiredPlan(
            widget.studentId,
            widget.detail.planId,
          );
      if (!mounted) return;
      widget.onMessage?.call('تم إنهاء الخطة وحفظ السور المكتملة في الأرشيف');
      widget.onClosed?.call();
      widget.onResolved();
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      widget.onMessage?.call(e.message, isError: true);
    } catch (_) {
      widget.onMessage?.call('تعذر إنهاء الخطة', isError: true);
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('yyyy-MM-dd');
    final isBusy = _isExtending || _isClosing;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.event_busy, color: AppColors.error, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'الخطة انتهت',
                    style: AppFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'انتهت فترة الخطة في ${dateFormat.format(widget.detail.planToDate)} '
              'ولا يزال لدى الطالب ${widget.detail.progress.pending} سطراً قيد الانتظار.',
              style: AppFonts.cairo(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى اختيار أحدى الخيارات الآتية:',
              style: AppFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'تمديد الخطة',
              icon: Icons.date_range,
              onPressed: isBusy ? null : _extendPlan,
              isLoading: _isExtending,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'انهاء الخطة وحذف السور التي لم يتم حفظها',
              icon: Icons.delete_outline,
              isOutlined: true,
              onPressed: isBusy ? null : _confirmClosePlan,
              isLoading: _isClosing,
            ),
          ],
        ),
      ),
    );
  }
}
