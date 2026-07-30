import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../../../plans/screens/bulk_plan_assignment_screen.dart';
import '../../../plans/screens/plan_levels_screen.dart';
import '../../models/dashboard_models.dart';
import '../../providers/dashboard_providers.dart';
import 'empty_students.dart';
import 'student_search_field.dart';
import 'students_list.dart';

class StudentsTab extends ConsumerWidget {
  const StudentsTab({
    super.key,
    required this.data,
    required this.isStudentsLoading,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
  });

  final DashboardPageData? data;
  final bool isStudentsLoading;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  List<StudentListItem> _studentsSortedByAttendance(List<StudentListItem> students) {
    final present = <StudentListItem>[];
    final absent = <StudentListItem>[];

    for (final student in students) {
      if (student.isPresentToday == 'غائب') {
        absent.add(student);
      } else {
        present.add(student);
      }
    }

    return [...present, ...absent];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final sortedStudents = _studentsSortedByAttendance(data!.students);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardPageProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'طلابي (${data!.students.length})',
                    style: AppFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (data!.students.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BulkPlanAssignmentScreen(
                            students: data!.students,
                          ),
                        ),
                      );
                      if (saved == true && context.mounted) {
                        ref.read(dashboardPageProvider.notifier).refresh();
                      }
                    },
                    icon: const Icon(Icons.group_add_rounded, size: 20),
                    label: Text(
                      'خطة جماعية',
                      style: AppFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'مستويات الخطة',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlanLevelsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StudentSearchField(
              controller: searchController,
              onChanged: onSearchChanged,
              onClear: () {
                searchController.clear();
                onSearchChanged('');
              },
            ),
            const SizedBox(height: 12),
            if (isStudentsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (data!.students.isEmpty)
              EmptyStudents(isSearchResult: searchQuery.isNotEmpty)
            else
              StudentsList(students: sortedStudents),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
