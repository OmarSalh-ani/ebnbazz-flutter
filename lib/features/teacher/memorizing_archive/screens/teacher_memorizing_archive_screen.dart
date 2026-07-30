import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../memorizing_archive/screens/memorizing_archive_screen.dart';
import '../providers/memorizing_archive_providers.dart';

class TeacherMemorizingArchiveScreen extends ConsumerWidget {
  const TeacherMemorizingArchiveScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final int studentId;
  final String studentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MemorizingArchiveScreen(
      studentName: studentName,
      loader: (query) => ref.read(memorizingArchiveApiProvider).getArchive(
            studentId,
            page: query.page,
            pageSize: query.pageSize,
            surahSearch: query.surahSearch,
          ),
    );
  }
}
