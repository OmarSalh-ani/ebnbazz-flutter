import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../children/models/student_plan_models.dart';
import '../../../memorizing_archive/models/memorizing_archive_item.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/memorizing_archive_api.dart';

final memorizingArchiveApiProvider = Provider<MemorizingArchiveApi>((ref) {
  return MemorizingArchiveApi(ref.watch(apiClientProvider));
});

class MemorizingArchiveKey {
  const MemorizingArchiveKey({
    required this.studentId,
    required this.page,
    this.pageSize = 20,
    this.surahSearch = '',
  });

  final int studentId;
  final int page;
  final int pageSize;
  final String surahSearch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemorizingArchiveKey &&
          studentId == other.studentId &&
          page == other.page &&
          pageSize == other.pageSize &&
          surahSearch == other.surahSearch;

  @override
  int get hashCode => Object.hash(studentId, page, pageSize, surahSearch);
}

final teacherMemorizingArchiveProvider = FutureProvider.family<
    PagedResult<MemorizingArchiveItem>, MemorizingArchiveKey>((ref, key) {
  return ref.read(memorizingArchiveApiProvider).getArchive(
        key.studentId,
        page: key.page,
        pageSize: key.pageSize,
        surahSearch: key.surahSearch,
      );
});
