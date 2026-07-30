import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../chat/screens/parent_chat_list_screen.dart';
import '../../students/screens/add_student_to_circle_screen.dart';
import '../../../../core/services/app_review_service.dart';
import '../providers/dashboard_providers.dart';
import '../providers/teacher_attendance_providers.dart';
import '../providers/teacher_admin_notes_provider.dart';
import '../screens/teacher_admin_notes_screen.dart';
import '../tabs/teacher_dashboard_tabs.dart';
import '../widgets/dashboard_widgets/teacher_admin_notes_popup.dart';
import '../widgets/dashboard_widgets/dashboard_tab_body.dart';
import '../widgets/dashboard_widgets/dashboard_error_state.dart';
import '../widgets/dashboard_widgets/settings_tab.dart';
import '../widgets/dashboard_widgets/voice_command_sheet.dart';
import 'package:masged_parent_app/features/home/screens/services_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _currentIndex = 0;
  bool _adminNotesPopupChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapAppReview());
      _maybeShowUnreadAdminNotesPopup();
    });
  }

  Future<void> _bootstrapAppReview() async {
    await AppReviewService.recordLaunch();
    await AppReviewService.maybePrompt();
  }

  Future<void> _maybeShowUnreadAdminNotesPopup() async {
    if (_adminNotesPopupChecked || !mounted) return;
    _adminNotesPopupChecked = true;

    try {
      final notes = await ref.read(teacherAdminNotesApiProvider).fetchAll();
      final unread = notes.where((n) => !n.isRead).toList();
      if (!mounted || unread.isEmpty) return;
      await showTeacherAdminNotesPopup(context, ref, unread);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(dashboardPageProvider.notifier).searchStudents(value);
    });
  }

  void _refreshMosqueProximityIfHomeVisible() {
    if (_currentIndex == TeacherDashboardTab.home) {
      ref.invalidate(mosqueProximityProvider);
    }
  }

  Future<void> _openRouteAndRefreshHome(Widget screen) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    _refreshMosqueProximityIfHomeVisible();
  }

  Widget _buildAdminNotesAction(int unreadCount) {
    final button = IconButton(
      icon: const Icon(Icons.campaign_outlined),
      tooltip: 'إشعارات الإدارة',
      onPressed: () => _openRouteAndRefreshHome(
        const TeacherAdminNotesScreen(),
      ),
    );
    final action = unreadCount <= 0
        ? button
        : Badge(
            label: Text('$unreadCount'),
            offset: const Offset(-2, 2),
            child: button,
          );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(dashboardPageProvider);
    final searchQuery = ref.read(dashboardPageProvider.notifier).search;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentIndex == TeacherDashboardTab.attendanceQr
          ? null
          : AppBar(
              title: Text(
                _currentIndex == TeacherDashboardTab.home
                    ? 'لوحة المعلم'
                    : _currentIndex == TeacherDashboardTab.students
                        ? 'قائمة الطلاب'
                        : _currentIndex == TeacherDashboardTab.services
                            ? 'الخدمات'
                            : 'الإعدادات',
                style: AppFonts.cairo(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.chat_outlined),
                  onPressed: () => _openRouteAndRefreshHome(
                    const ParentChatListScreen(),
                  ),
                ),
                _buildAdminNotesAction(
                  pageState.valueOrNull?.unreadAdminNotesCount ?? 0,
                ),
              ],
            ),
      body: _currentIndex == TeacherDashboardTab.attendanceQr
          ? const AttendanceScreen()
          : _currentIndex == TeacherDashboardTab.settings
              ? SettingsTab(data: pageState.valueOrNull)
              : _currentIndex == TeacherDashboardTab.services
                  ? const ServicesScreen(embeddedInDashboard: true)
                  : pageState.when(
                      loading: () {
                        final previous = pageState.valueOrNull;
                        return DashboardTabBody(
                          currentIndex: _currentIndex,
                          data: previous,
                          searchQuery: searchQuery,
                          isStudentsLoading: previous == null,
                          searchController: _searchController,
                          onSearchChanged: _onSearchChanged,
                        );
                      },
                      error: (error, _) => DashboardErrorState(
                        error: error,
                        onRetry: () => ref.invalidate(dashboardPageProvider),
                      ),
                      data: (data) => DashboardTabBody(
                        currentIndex: _currentIndex,
                        data: data,
                        searchQuery: searchQuery,
                        isStudentsLoading: false,
                        searchController: _searchController,
                        onSearchChanged: _onSearchChanged,
                      ),
                    ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            final wasOnHome = _currentIndex == TeacherDashboardTab.home;
            setState(() {
              _currentIndex = index;
            });
            if (index == TeacherDashboardTab.home && wasOnHome) {
              ref.invalidate(mosqueProximityProvider);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary.withValues(alpha: 0.6),
          selectedLabelStyle: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: AppFonts.cairo(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'الطلاب',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: 'الحضور',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'الخدمات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == TeacherDashboardTab.attendanceQr ||
              _currentIndex == TeacherDashboardTab.settings
          ? null
          : _currentIndex == TeacherDashboardTab.students
              ? FloatingActionButton(
                  onPressed: () async {
                    final added = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddStudentToCircleScreen(),
                      ),
                    );
                    if (added == true && mounted) {
                      ref.read(dashboardPageProvider.notifier).refresh();
                      ref.invalidate(attendanceStudentsProvider);
                    }
                  },
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                )
              : FloatingActionButton(
                  onPressed: () => showVoiceCommandBottomSheet(context),
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  child: const Icon(Icons.mic, color: Colors.white, size: 28),
                ),
    );
  }
}
