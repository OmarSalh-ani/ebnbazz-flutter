import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memorizing_archive/screens/memorizing_archive_screen.dart';
import '../providers/students_provider.dart';

class ParentMemorizingArchiveScreen extends ConsumerWidget {
  const ParentMemorizingArchiveScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MemorizingArchiveScreen(
      studentName: studentName,
      loader: (query) => ref.read(studentsApiServiceProvider).getMemorizingArchive(
            studentId,
            page: query.page,
            pageSize: query.pageSize,
            surahSearch: query.surahSearch,
          ),
    );
  }
}
