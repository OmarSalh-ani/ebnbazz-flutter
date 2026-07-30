import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:masged_parent_app/splash/splash_colors.dart';

import '../models/public_registration_models.dart';
import '../models/registration_student_form_state.dart';
import 'registration_student_card.dart';

class RegistrationStudentsTabs extends StatefulWidget {
  const RegistrationStudentsTabs({
    super.key,
    required this.students,
    required this.config,
    required this.maxStudents,
    required this.onAddStudent,
    required this.onRemoveStudent,
    required this.onChanged,
  });

  final List<RegistrationStudentFormState> students;
  final PublicRegistrationConfig config;
  final int maxStudents;
  final VoidCallback onAddStudent;
  final ValueChanged<int> onRemoveStudent;
  final VoidCallback onChanged;

  @override
  State<RegistrationStudentsTabs> createState() =>
      _RegistrationStudentsTabsState();
}

class _RegistrationStudentsTabsState extends State<RegistrationStudentsTabs>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Map<RegistrationStudentFormState, VoidCallback> _nameListeners = {};

  bool get _canAddStudent => widget.students.length < widget.maxStudents;

  int get _tabCount => widget.students.length + (_canAddStudent ? 1 : 0);

  int get _addTabIndex => widget.students.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _attachNameListeners();
  }

  @override
  void didUpdateWidget(RegistrationStudentsTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    _detachRemovedListeners();

    if (_tabCount != _tabController.length) {
      final previousIndex = _tabController.index;
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();

      final addedStudent =
          widget.students.length > oldWidget.students.length;
      final initialIndex = addedStudent
          ? widget.students.length - 1
          : previousIndex.clamp(0, widget.students.length - 1);

      _tabController = TabController(
        length: _tabCount,
        vsync: this,
        initialIndex: initialIndex,
      );
      _tabController.addListener(_onTabChanged);
    }

    _attachNameListeners();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    for (final entry in _nameListeners.entries) {
      entry.key.fullNameController.removeListener(entry.value);
    }
    _nameListeners.clear();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    if (_canAddStudent && _tabController.index == _addTabIndex) {
      widget.onAddStudent();
      return;
    }

    setState(() {});
  }

  void _attachNameListeners() {
    for (final student in widget.students) {
      if (_nameListeners.containsKey(student)) continue;
      void listener() => setState(() {});
      _nameListeners[student] = listener;
      student.fullNameController.addListener(listener);
    }
  }

  void _detachRemovedListeners() {
    final removed = _nameListeners.keys
        .where((student) => !widget.students.contains(student))
        .toList();
    for (final student in removed) {
      student.fullNameController.removeListener(_nameListeners[student]!);
      _nameListeners.remove(student);
    }
  }

  String _tabLabel(int index) {
    final name = widget.students[index].fullNameController.text.trim();
    if (name.isEmpty) return 'طالب ${index + 1}';
    final parts = name.split(RegExp(r'\s+'));
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final activeStudentIndex =
        _tabController.index.clamp(0, widget.students.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: AppFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: AppFonts.cairo(fontSize: 14),
            labelColor: SplashColors.gold,
            unselectedLabelColor: SplashColors.whiteText.withValues(alpha: 0.55),
            indicatorColor: SplashColors.gold,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            tabs: [
              ...List.generate(
                widget.students.length,
                (index) => Tab(text: _tabLabel(index)),
              ),
              if (_canAddStudent)
                Tab(
                  height: 46,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SplashColors.gold.withValues(alpha: 0.55),
                      ),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: SplashColors.gold,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IndexedStack(
          index: activeStudentIndex,
          children: List.generate(widget.students.length, (index) {
            return RegistrationStudentCard(
              key: ValueKey(widget.students[index]),
              index: index,
              state: widget.students[index],
              config: widget.config,
              embeddedInTabs: true,
              canRemove: widget.students.length > 1,
              onRemove: () => widget.onRemoveStudent(index),
              onChanged: widget.onChanged,
            );
          }),
        ),
      ],
    );
  }
}
