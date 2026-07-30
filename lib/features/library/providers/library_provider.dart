import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/center_release_model.dart';
import '../services/library_api_service.dart';

final libraryApiServiceProvider = Provider((ref) => LibraryApiService());

final libraryProvider = FutureProvider<List<CenterReleaseModel>>((ref) async {
  return ref.read(libraryApiServiceProvider).getReleases();
});
