import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/revise_api.dart';
import '../models/revise_models.dart';

final reviseApiProvider = Provider<ReviseApi>((ref) {
  return ReviseApi(ref.watch(apiClientProvider));
});

class ReviseRepository {
  ReviseRepository(this._api);

  final ReviseApi _api;

  Future<String> create({
    required int studentId,
    required String type,
    required int surahId,
    required String surahName,
    required int fromAyah,
    required int toAyah,
  }) {
    final request = buildCreateReviseRequest(
      type: type,
      surahId: surahId,
      surahName: surahName,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );
    return _api.create(studentId, request);
  }
}

final reviseRepositoryProvider = Provider<ReviseRepository>((ref) {
  return ReviseRepository(ref.watch(reviseApiProvider));
});

final revisePageProvider = FutureProvider.autoDispose
    .family<RevisePageData, int>((ref, studentId) {
  return ref.watch(reviseApiProvider).getPage(studentId);
});

final reviseSurahAyahsProvider = FutureProvider.autoDispose
    .family<List<int>, int>((ref, surahId) {
  return ref.watch(reviseApiProvider).getAyahNumbers(surahId);
});
