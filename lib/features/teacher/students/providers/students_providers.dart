import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/students_api.dart';
import '../models/available_student.dart';

const availableStudentsPageSize = 20;

final studentsApiProvider = Provider<StudentsApi>((ref) {
  return StudentsApi(ref.watch(apiClientProvider));
});

final availableStudentsSearchProvider =
    NotifierProvider<AvailableStudentsSearchController, String>(
  AvailableStudentsSearchController.new,
);

class AvailableStudentsSearchController extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String term) {
    state = term.trim();
  }
}

class AvailableStudentsPageState {
  const AvailableStudentsPageState({
    required this.students,
    required this.page,
    required this.totalPages,
    required this.search,
    this.isLoadingMore = false,
  });

  final List<AvailableStudent> students;
  final int page;
  final int totalPages;
  final String search;
  final bool isLoadingMore;

  bool get hasMore => page < totalPages;

  AvailableStudentsPageState copyWith({
    List<AvailableStudent>? students,
    int? page,
    int? totalPages,
    String? search,
    bool? isLoadingMore,
  }) {
    return AvailableStudentsPageState(
      students: students ?? this.students,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final availableStudentsControllerProvider =
    AsyncNotifierProvider<AvailableStudentsController, AvailableStudentsPageState>(
  AvailableStudentsController.new,
);

class AvailableStudentsController
    extends AsyncNotifier<AvailableStudentsPageState> {
  @override
  Future<AvailableStudentsPageState> build() async {
    final search = ref.watch(availableStudentsSearchProvider);
    return _fetchPage(search: search, page: 1);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = await ref.read(studentsApiProvider).getAvailableStudents(
            searchTerm: current.search.isEmpty ? null : current.search,
            page: current.page + 1,
            pageSize: availableStudentsPageSize,
          );

      final previous = state.valueOrNull ?? current;
      state = AsyncData(
        AvailableStudentsPageState(
          students: [...previous.students, ...nextPage.items],
          page: nextPage.page,
          totalPages: nextPage.totalPages,
          search: previous.search,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<AvailableStudentsPageState> _fetchPage({
    required String search,
    required int page,
  }) async {
    final result = await ref.read(studentsApiProvider).getAvailableStudents(
          searchTerm: search.isEmpty ? null : search,
          page: page,
          pageSize: availableStudentsPageSize,
        );

    return AvailableStudentsPageState(
      students: result.items,
      page: result.page,
      totalPages: result.totalPages,
      search: search,
    );
  }
}
