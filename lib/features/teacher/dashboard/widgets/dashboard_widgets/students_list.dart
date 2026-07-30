import 'package:flutter/material.dart';

import '../../models/dashboard_models.dart';
import 'student_card.dart';

class StudentsList extends StatelessWidget {
  const StudentsList({
    super.key,
    required this.students,
  });

  final List<StudentListItem> students;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = students[index];
        return StudentCard(student: student);
      },
    );
  }
}
