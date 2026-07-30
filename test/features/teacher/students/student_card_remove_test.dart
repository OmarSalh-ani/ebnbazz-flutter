import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masged_parent_app/app/providers/app_role_provider.dart';
import 'package:masged_parent_app/features/teacher/dashboard/models/dashboard_models.dart';
import 'package:masged_parent_app/features/teacher/dashboard/providers/dashboard_providers.dart';
import 'package:masged_parent_app/features/teacher/dashboard/widgets/dashboard_widgets/student_card.dart';
import 'package:masged_parent_app/features/teacher/students/data/students_api.dart';
import 'package:masged_parent_app/features/teacher/students/providers/students_providers.dart';
import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import 'package:masged_parent_app/teacher_core/storage/auth_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_student_to_circle_screen_test.dart';

const _dashboardStudent = StudentListItem(
  id: 101,
  name: 'أحمد محمد',
  age: 12,
  group: 'A',
  planLevelName: 'جزء عم',
  isPresentToday: 'حاضر',
  departureStatusToday: '',
  departureTimeToday: '',
  fatherPhone: '99998888',
);

class TrackingDashboardController extends DashboardPageController {
  int refreshCount = 0;

  @override
  Future<DashboardPageData> build() async {
    return DashboardPageData(
      teacherName: 'معلم',
      circleName: 'حلقة',
      isWorkDayToday: true,
      statistics: const StudentsStatistics(
        totalStudents: 1,
        presentStudents: 1,
        absentStudents: 0,
        departedStudents: 0,
      ),
      unreadAdminNotesCount: 0,
      students: const [_dashboardStudent],
    );
  }

  @override
  Future<void> refresh() async {
    refreshCount++;
    state = AsyncValue.data(await build());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStudentsApi fakeApi;
  late TrackingDashboardController dashboardController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeApi = FakeStudentsApi(TeacherApiClient(AuthStorage(prefs)));
    dashboardController = TrackingDashboardController();
  });

  testWidgets('StudentCard remove-from-circle confirms and calls API', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          studentsApiProvider.overrideWithValue(fakeApi),
          dashboardPageProvider.overrideWith(() => dashboardController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StudentCard(student: _dashboardStudent),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('إزالة من الحلقة'));
    await tester.pumpAndSettle();

    expect(find.text('تأكيد الإزالة'), findsOneWidget);
    expect(find.text('هل تريد إزالة "أحمد محمد" من الحلقة؟'), findsOneWidget);

    await tester.tap(find.text('إزالة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(fakeApi.lastRemovedId, _dashboardStudent.id);
    expect(find.text(fakeApi.removeMessage), findsOneWidget);
    expect(dashboardController.refreshCount, 1);
  });

  testWidgets('StudentCard remove-from-circle can be cancelled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          studentsApiProvider.overrideWithValue(fakeApi),
          dashboardPageProvider.overrideWith(() => dashboardController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StudentCard(student: _dashboardStudent),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('إزالة من الحلقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(fakeApi.lastRemovedId, isNull);
  });
}
