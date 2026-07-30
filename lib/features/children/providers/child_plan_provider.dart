import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student_plan_models.dart';
import 'students_provider.dart';

final childPlanOverviewProvider =
    FutureProvider.autoDispose.family<ParentPlanOverview, String>(
  (ref, studentId) {
    return ref.read(studentsApiServiceProvider).getPlanOverview(studentId);
  },
);

class ChildPlanRowsKey {
  const ChildPlanRowsKey({
    required this.studentId,
    required this.planType,
    required this.page,
    this.pageSize = 10,
  });

  final String studentId;
  final String planType;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildPlanRowsKey &&
          studentId == other.studentId &&
          planType == other.planType &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hash(studentId, planType, page, pageSize);
}

final childPlanRowsProvider = FutureProvider.autoDispose
    .family<PagedResult<ParentPlanRow>, ChildPlanRowsKey>((ref, key) {
  return ref.read(studentsApiServiceProvider).getPlanRows(
        key.studentId,
        planType: key.planType,
        page: key.page,
        pageSize: key.pageSize,
      );
});
