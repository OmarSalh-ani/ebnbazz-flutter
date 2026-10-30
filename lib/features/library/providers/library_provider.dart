import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library_kind.dart';
import '../models/center_release_model.dart';
import '../services/library_api_service.dart';

final libraryApiServiceProvider = Provider((ref) => LibraryApiService());

final libraryProvider =
    FutureProvider.family<List<CenterReleaseModel>, LibraryKind>((ref, kind) async {
  return ref.read(libraryApiServiceProvider).getReleases(kind);
});
