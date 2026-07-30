import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/core/utils/arabic_search_utils.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../models/selectable_student_row.dart';

class SelectableStudentsList extends StatefulWidget {
  const SelectableStudentsList({
    super.key,
    required this.title,
    required this.students,
    required this.selectedIds,
    required this.onSelectionChanged,
    this.emptyMessage = 'لا يوجد طلاب',
    this.noResultsMessage = 'لا توجد نتائج للبحث',
    this.searchHint = 'بحث باسم الطالب',
    this.searchStartsWith = false,
    this.onSearchChanged,
    this.initialSearch = '',
  });

  final String title;
  final List<SelectableStudentRow> students;
  final Set<int> selectedIds;
  final void Function(int id, bool selected) onSelectionChanged;
  final String emptyMessage;
  final String noResultsMessage;
  final String searchHint;
  final bool searchStartsWith;
  final ValueChanged<String>? onSearchChanged;
  final String initialSearch;

  @override
  State<SelectableStudentsList> createState() => _SelectableStudentsListState();
}

class _SelectableStudentsListState extends State<SelectableStudentsList> {
  late final TextEditingController _searchController;
  late String _searchQuery;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearch;
    _searchController = TextEditingController(text: widget.initialSearch);
  }

  @override
  void didUpdateWidget(SelectableStudentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onSearchChanged != null &&
        oldWidget.initialSearch != widget.initialSearch &&
        _searchController.text != widget.initialSearch) {
      _searchController.text = widget.initialSearch;
      _searchQuery = widget.initialSearch;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SelectableStudentRow> get _filtered {
    if (widget.onSearchChanged != null || _searchQuery.trim().isEmpty) {
      return widget.students;
    }
    final matches = widget.searchStartsWith
        ? arabicNameStartsWith
        : arabicNameMatches;
    return widget.students
        .where((s) => matches(s.name, _searchQuery))
        .toList();
  }

  String get _emptyListMessage {
    final hasSearchQuery = _searchQuery.trim().isNotEmpty;
    return hasSearchQuery ? widget.noResultsMessage : widget.emptyMessage;
  }

  @override
  Widget build(BuildContext context) {
    // Keep search visible for server-side search even when the list is empty.
    if (widget.students.isEmpty && widget.onSearchChanged == null) {
      return Text(
        widget.emptyMessage,
        style: AppFonts.cairo(color: AppColors.textSecondary),
      );
    }

    final filtered = _filtered;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (v) {
              setState(() => _searchQuery = v);
              widget.onSearchChanged?.call(v);
            },
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: AppFonts.cairo(color: AppColors.textHint),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        widget.onSearchChanged?.call('');
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
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _emptyListMessage,
                style: AppFonts.cairo(color: AppColors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = filtered[index];
                final checked = widget.selectedIds.contains(student.id);
                return CheckboxListTile(
                  secondary: _buildAvatar(student),
                  title: Text(
                    student.name,
                    style: AppFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: student.subtitle != null &&
                          student.subtitle!.isNotEmpty
                      ? Text(
                          student.subtitle!,
                          style: AppFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : null,
                  value: checked,
                  onChanged: (v) {
                    widget.onSelectionChanged(student.id, v ?? false);
                  },
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(SelectableStudentRow student) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primaryLight,
      backgroundImage:
          student.imageUrl != null ? NetworkImage(student.imageUrl!) : null,
      child: student.imageUrl == null
          ? const Icon(Icons.person, color: AppColors.primary, size: 22)
          : null,
    );
  }
}
