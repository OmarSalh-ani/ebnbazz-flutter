import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/teacher_core/network/api_exception.dart';
import '../../shared/models/selectable_student_row.dart';
import '../../shared/widgets/selectable_students_list.dart';
import '../models/available_student.dart';
import '../providers/students_providers.dart';

class AddStudentToCircleScreen extends ConsumerStatefulWidget {
  const AddStudentToCircleScreen({super.key});

  @override
  ConsumerState<AddStudentToCircleScreen> createState() =>
      _AddStudentToCircleScreenState();
}

class _AddStudentToCircleScreenState
    extends ConsumerState<AddStudentToCircleScreen> {
  final Set<int> _selectedIds = {};
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;

    ref.read(availableStudentsControllerProvider.notifier).loadMore();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(availableStudentsSearchProvider.notifier).setSearch(value);
    });
  }

  List<SelectableStudentRow> _mapRows(List<AvailableStudent> students) {
    return students
        .map(
          (s) => SelectableStudentRow(
            id: s.id,
            name: s.studentName,
            subtitle: s.age > 0 ? 'العمر: ${s.age} سنة' : s.fatherPhone,
          ),
        )
        .toList();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppFonts.cairo()),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تم بنجاح',
          textAlign: TextAlign.right,
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: AppFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'حسناً',
              style: AppFonts.cairo(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCircle() async {
    if (_selectedIds.isEmpty) {
      _showMessage('يرجى اختيار طالب واحد على الأقل', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final message = await ref
          .read(studentsApiProvider)
          .addStudentsToCircle(_selectedIds.toList());

      if (!mounted) return;

      await _showSuccessDialog(message);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceFirst('Exception:', '').trim(),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(availableStudentsControllerProvider);
    final searchTerm = ref.watch(availableStudentsSearchProvider);
    final pageState = studentsAsync.valueOrNull;
    final isSearching =
        studentsAsync.isLoading && pageState != null && !pageState.isLoadingMore;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'إضافة طالب للحلقة',
          style: AppFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _addToCircle,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'إضافة للحلقة',
                    style: AppFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(availableStudentsControllerProvider);
          await ref.read(availableStudentsControllerProvider.future);
        },
        child: studentsAsync.when(
          loading: () {
            if (pageState == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildStudentsBody(
              pageState,
              searchTerm: searchTerm,
              isSearching: true,
            );
          },
          error: (e, _) => _buildStudentsBody(
            AvailableStudentsPageState(
              students: const [],
              page: 1,
              totalPages: 0,
              search: searchTerm,
            ),
            searchTerm: searchTerm,
            errorMessage: _errorMessage(e),
          ),
          data: (loadedState) => _buildStudentsBody(
            loadedState,
            searchTerm: searchTerm,
            isSearching: isSearching,
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString().replaceFirst('Exception:', '').trim();
  }

  Widget _buildStudentsBody(
    AvailableStudentsPageState pageState, {
    required String searchTerm,
    bool isSearching = false,
    String? errorMessage,
  }) {
    final students = pageState.students;

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              errorMessage,
              style: AppFonts.cairo(color: AppColors.error),
            ),
          ),
        SelectableStudentsList(
            title: 'اختر الطلاب لإضافتهم للحلقة',
            students: _mapRows(students),
            selectedIds: _selectedIds,
            initialSearch: searchTerm,
            onSearchChanged: _onSearchChanged,
            onSelectionChanged: (id, selected) {
              setState(() {
                if (selected) {
                  _selectedIds.add(id);
                } else {
                  _selectedIds.remove(id);
                }
              });
            },
            emptyMessage: pageState.search.isEmpty
                ? 'لا يوجد طلاب غير مسجلين في حلقة'
                : 'لا توجد نتائج للبحث',
          ),
        if (isSearching)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (pageState.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}
