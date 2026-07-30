import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../../data/teacher_admin_notes_api.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/teacher_admin_notes_provider.dart';
import 'teacher_admin_note_card.dart';

const _closeCountdownSeconds = 10;

Future<void> showTeacherAdminNotesPopup(
  BuildContext context,
  WidgetRef ref,
  List<TeacherAdminNoteItem> notes,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _TeacherAdminNotesPopupDialog(
      notes: notes,
      onClose: () async {
        Navigator.of(dialogContext).pop();
        try {
          await ref.read(teacherAdminNotesApiProvider).markAllRead();
          ref.invalidate(teacherAdminNotesProvider);
          ref.invalidate(dashboardPageProvider);
        } catch (_) {}
      },
    ),
  );
}

class _TeacherAdminNotesPopupDialog extends StatefulWidget {
  const _TeacherAdminNotesPopupDialog({
    required this.notes,
    required this.onClose,
  });

  final List<TeacherAdminNoteItem> notes;
  final Future<void> Function() onClose;

  @override
  State<_TeacherAdminNotesPopupDialog> createState() =>
      _TeacherAdminNotesPopupDialogState();
}

class _TeacherAdminNotesPopupDialogState
    extends State<_TeacherAdminNotesPopupDialog> {
  int _secondsLeft = _closeCountdownSeconds;
  Timer? _timer;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (_secondsLeft > 0 || _isClosing) return;
    setState(() => _isClosing = true);
    await widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final canClose = _secondsLeft <= 0 && !_isClosing;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'إشعار من الإدارة',
                style: AppFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ],
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  TeacherAdminNoteCard(note: widget.notes[i]),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canClose ? _handleClose : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isClosing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _secondsLeft > 0
                          ? 'إغلاق ($_secondsLeft)'
                          : 'إغلاق',
                      style: AppFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
