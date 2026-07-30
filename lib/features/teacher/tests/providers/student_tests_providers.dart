import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/student_tests_api.dart';
import '../data/student_tests_repository.dart';
import '../data/test_certificate_api.dart';
import '../models/student_test_models.dart';

final studentTestsApiProvider = Provider<StudentTestsApi>((ref) {
  return StudentTestsApi(ref.watch(apiClientProvider));
});

final testCertificateApiProvider = Provider<TestCertificateApi>((ref) {
  return TestCertificateApi(ref.watch(apiClientProvider));
});

final studentTestsRepositoryProvider = Provider<StudentTestsRepository>((ref) {
  return StudentTestsRepository(ref.watch(studentTestsApiProvider));
});

final studentTestsWithDetailsProvider = FutureProvider.autoDispose
    .family<List<StudentTestDetail>, int>((ref, studentId) {
  return ref
      .watch(studentTestsRepositoryProvider)
      .loadTestsWithDetails(studentId);
});

final studentTestsPageProvider = FutureProvider.autoDispose
    .family<StudentTestsPage, int>((ref, studentId) {
  return ref.watch(studentTestsRepositoryProvider).getTestsPage(studentId);
});
