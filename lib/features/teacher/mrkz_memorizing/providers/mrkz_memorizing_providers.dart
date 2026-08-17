import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/mrkz_memorizing_revision_api.dart';
import '../models/mrkz_memorizing_item.dart';

final mrkzMemorizingRevisionApiProvider =
    Provider<MrkzMemorizingRevisionApi>((ref) {
  return MrkzMemorizingRevisionApi(ref.watch(apiClientProvider));
});

class MrkzMemorizingArchiveKey {
  const MrkzMemorizingArchiveKey({
    required this.studentId,
    this.mtnSearch = '',
  });

  final int studentId;
  final String mtnSearch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MrkzMemorizingArchiveKey &&
          studentId == other.studentId &&
          mtnSearch == other.mtnSearch;

  @override
  int get hashCode => Object.hash(studentId, mtnSearch);
}

final mrkzMemorizingArchiveProvider = FutureProvider.family<
    List<MrkzMemorizingItem>, MrkzMemorizingArchiveKey>((ref, key) async {
  final items =
      await ref.read(mrkzMemorizingRevisionApiProvider).getMergedArchive(
            key.studentId,
          );

  final search = key.mtnSearch.trim();
  if (search.isEmpty) return items;

  return items
      .where((item) => item.mtnName.contains(search))
      .toList(growable: false);
});
