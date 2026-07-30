import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/adhkar_category.dart';
import '../models/adhkar_category_summary.dart';
import '../services/adhkar_api_service.dart';
import '../../children/models/student_plan_models.dart';

final adhkarApiServiceProvider = Provider<AdhkarApiService>((ref) {
  return AdhkarApiService();
});

class AdhkarCategoryListArgs {
  const AdhkarCategoryListArgs({
    this.ids,
    this.search = '',
    this.page = 1,
    this.pageSize = 20,
  });

  final List<int>? ids;
  final String search;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is AdhkarCategoryListArgs &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize &&
        _sameIds(other.ids, ids);
  }

  @override
  int get hashCode => Object.hash(
        search,
        page,
        pageSize,
        ids == null ? null : Object.hashAll(ids!),
      );

  static bool _sameIds(List<int>? a, List<int>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final adhkarCategoryListProvider = FutureProvider.family<
    PagedResult<AdhkarCategorySummary>, AdhkarCategoryListArgs>((ref, args) {
  return ref.read(adhkarApiServiceProvider).getCategories(
        page: args.page,
        pageSize: args.pageSize,
        search: args.search,
        ids: args.ids,
      );
});

final adhkarCategoryProvider =
    FutureProvider.family<AdhkarCategory, int>((ref, categoryId) {
  return ref.read(adhkarApiServiceProvider).getCategory(categoryId);
});
