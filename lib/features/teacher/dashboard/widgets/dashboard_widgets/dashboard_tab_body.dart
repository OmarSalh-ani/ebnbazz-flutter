import 'package:flutter/material.dart';

import '../../models/dashboard_models.dart';
import '../../tabs/teacher_dashboard_tabs.dart';
import 'package:masged_parent_app/features/home/screens/services_screen.dart';

import 'home_tab.dart';
import 'settings_tab.dart';
import 'students_tab.dart';

class DashboardTabBody extends StatelessWidget {
  const DashboardTabBody({
    super.key,
    required this.currentIndex,
    required this.data,
    required this.searchQuery,
    required this.isStudentsLoading,
    required this.searchController,
    required this.onSearchChanged,
  });

  final int currentIndex;
  final DashboardPageData? data;
  final String searchQuery;
  final bool isStudentsLoading;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    switch (currentIndex) {
      case TeacherDashboardTab.home:
        return HomeTab(data: data);
      case TeacherDashboardTab.students:
        return StudentsTab(
          data: data,
          isStudentsLoading: isStudentsLoading,
          searchQuery: searchQuery,
          searchController: searchController,
          onSearchChanged: onSearchChanged,
        );
      case TeacherDashboardTab.services:
        return const ServicesScreen(embeddedInDashboard: true);
      case TeacherDashboardTab.settings:
        return SettingsTab(data: data);
      default:
        return const SizedBox.shrink();
    }
  }
}
