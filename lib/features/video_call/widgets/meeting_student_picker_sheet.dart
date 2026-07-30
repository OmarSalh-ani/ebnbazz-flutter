import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/shared/widgets/custom_button.dart';
import '../../teacher/dashboard/models/dashboard_models.dart';

/// Bottom sheet to search and select students for a video meeting.
Future<List<int>?> showMeetingStudentPickerSheet({
  required BuildContext context,
  required List<StudentListItem> students,
  required Set<int> alreadyInvitedIds,
  required String title,
  String confirmLabel = 'تأكيد',
  bool allowAlreadyInvited = false,
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _MeetingStudentPickerSheet(
      students: students,
      alreadyInvitedIds: alreadyInvitedIds,
      title: title,
      confirmLabel: confirmLabel,
      allowAlreadyInvited: allowAlreadyInvited,
    ),
  );
}

class _MeetingStudentPickerSheet extends StatefulWidget {
  const _MeetingStudentPickerSheet({
    required this.students,
    required this.alreadyInvitedIds,
    required this.title,
    required this.confirmLabel,
    required this.allowAlreadyInvited,
  });

  final List<StudentListItem> students;
  final Set<int> alreadyInvitedIds;
  final String title;
  final String confirmLabel;
  final bool allowAlreadyInvited;

  @override
  State<_MeetingStudentPickerSheet> createState() =>
      _MeetingStudentPickerSheetState();
}

class _MeetingStudentPickerSheetState extends State<_MeetingStudentPickerSheet> {
  final _searchController = TextEditingController();
  final Map<int, bool> _selected = {};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentListItem> get _filtered {
    final q = _query.trim().toLowerCase();
    var list = widget.students;
    if (!widget.allowAlreadyInvited) {
      list = list
          .where((s) => !widget.alreadyInvitedIds.contains(s.id))
          .toList();
    }
    if (q.isEmpty) return list;
    return list.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  void _toggle(int id, bool? value) {
    if (!widget.allowAlreadyInvited && widget.alreadyInvitedIds.contains(id)) {
      return;
    }
    setState(() => _selected[id] = value ?? false);
  }

  void _confirm() {
    final ids = _selected.entries
        .where((e) => e.value && !widget.alreadyInvitedIds.contains(e.key))
        .map((e) => e.key)
        .toList();
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اختر طالباً واحداً على الأقل',
            style: AppFonts.cairo(),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(ids);
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.85;
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                widget.title,
                style: AppFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'بحث باسم الطالب',
                  hintStyle: AppFonts.cairo(color: AppColors.textHint),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _query.isNotEmpty
                            ? 'لا توجد نتائج'
                            : 'لا يوجد طلاب متاحون',
                        style: AppFonts.cairo(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = filtered[index];
                        final invited =
                            widget.alreadyInvitedIds.contains(student.id);
                        final checked = invited || (_selected[student.id] ?? false);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: invited
                              ? null
                              : (v) => _toggle(student.id, v),
                          secondary: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: student.imageUrl != null
                                ? NetworkImage(student.imageUrl!)
                                : null,
                            child: student.imageUrl == null
                                ? Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 22,
                                  )
                                : null,
                          ),
                          title: Text(
                            student.name,
                            style: AppFonts.cairo(
                              fontWeight: FontWeight.w600,
                              color: invited
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: invited
                              ? Text(
                                  'مدعو بالفعل',
                                  style: AppFonts.cairo(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomButton(
                text: widget.confirmLabel,
                onPressed: _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
