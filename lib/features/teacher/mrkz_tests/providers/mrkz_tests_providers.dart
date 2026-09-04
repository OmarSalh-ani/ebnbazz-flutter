import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/mrkz_tests_api.dart';
import '../models/mrkz_test_models.dart';

final mrkzTestsApiProvider = Provider<MrkzTestsApi>((ref) {
  return MrkzTestsApi(ref.watch(apiClientProvider));
});

final mrkzTestDefinitionsProvider = FutureProvider.autoDispose
    .family<List<MrkzTestDefinitionOption>, int>((ref, studentId) {
  return ref.watch(mrkzTestsApiProvider).getDefinitions(studentId);
});

final mrkzTestsPageProvider = FutureProvider.autoDispose
    .family<MrkzTestsPage, int>((ref, studentId) {
  return ref.watch(mrkzTestsApiProvider).getTests(studentId);
});
