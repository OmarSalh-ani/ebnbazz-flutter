import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masged_parent_app/app/providers/app_role_provider.dart';
import 'package:masged_parent_app/features/children/models/student_plan_models.dart';
import 'package:masged_parent_app/features/teacher/students/data/students_api.dart';
import 'package:masged_parent_app/features/teacher/students/models/available_student.dart';
import 'package:masged_parent_app/features/teacher/students/providers/students_providers.dart';
import 'package:masged_parent_app/features/teacher/students/screens/add_student_to_circle_screen.dart';
import 'package:masged_parent_app/features/teacher/shared/widgets/selectable_students_list.dart';
import 'package:masged_parent_app/features/teacher/shared/models/selectable_student_row.dart';
import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import 'package:masged_parent_app/teacher_core/storage/auth_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _studentA = AvailableStudent(
  id: 101,
  studentName: 'أحمد محمد',
  fatherPhone: '99998888',
  age: 12,
);

const _studentB = AvailableStudent(
  id: 102,
  studentName: 'سارة علي',
  fatherPhone: '77776666',
  age: 10,
);

class FakeStudentsApi extends StudentsApi {
  FakeStudentsApi(super.client, {List<AvailableStudent>? availableStudents})
      : _availableStudents = List<AvailableStudent>.from(
          availableStudents ?? const [],
        );

  final List<AvailableStudent> _availableStudents;
  List<int>? lastAddedIds;
  int? lastRemovedId;
  String? lastSearchTerm;
  int? lastRequestedPage;
  int lastRequestedPageSize = 20;
  String addMessage = 'تم إضافة الطلاب إلى الحلقة';
  String removeMessage = 'تم إزالة الطالب من الحلقة';

  void setAvailableStudents(List<AvailableStudent> students) {
    _availableStudents
      ..clear()
      ..addAll(students);
  }

  List<AvailableStudent> _filteredStudents(String? searchTerm) {
    final trimmed = searchTerm?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return List<AvailableStudent>.from(_availableStudents);
    }
    return _availableStudents
        .where((s) => s.studentName.startsWith(trimmed))
        .toList();
  }

  @override
  Future<PagedResult<AvailableStudent>> getAvailableStudents({
    String? searchTerm,
    int page = 1,
    int pageSize = 20,
  }) async {
    lastSearchTerm = searchTerm;
    lastRequestedPage = page;
    lastRequestedPageSize = pageSize;

    final filtered = _filteredStudents(searchTerm);
    final totalCount = filtered.length;
    final totalPages =
        totalCount == 0 ? 0 : (totalCount / pageSize).ceil();
    final start = (page - 1) * pageSize;
    final items = start >= filtered.length
        ? <AvailableStudent>[]
        : filtered.skip(start).take(pageSize).toList();

    return PagedResult(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: totalPages,
    );
  }

  @override
  Future<String> addStudentsToCircle(List<int> studentIds) async {
    lastAddedIds = List<int>.from(studentIds);
    return addMessage;
  }

  @override
  Future<String> removeStudentFromCircle(int studentId) async {
    lastRemovedId = studentId;
    return removeMessage;
  }
}

Future<void> _pumpAddScreen(
  WidgetTester tester, {
  required FakeStudentsApi fakeApi,
  List<AvailableStudent> students = const [_studentA, _studentB],
}) async {
  fakeApi.setAvailableStudents(students);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        studentsApiProvider.overrideWithValue(fakeApi),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddStudentToCircleScreen(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStudentsApi fakeApi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeApi = FakeStudentsApi(TeacherApiClient(AuthStorage(prefs)));
  });

  group('SelectableStudentsList selection toggle', () {
    testWidgets('checks and unchecks students', (tester) async {
      final selectedIds = <int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SelectableStudentsList(
                  title: 'اختر الطلاب',
                  students: [
                    SelectableStudentRow(
                      id: _studentA.id,
                      name: _studentA.studentName,
                      subtitle: 'العمر: ${_studentA.age}',
                    ),
                    SelectableStudentRow(
                      id: _studentB.id,
                      name: _studentB.studentName,
                      subtitle: 'العمر: ${_studentB.age}',
                    ),
                  ],
                  selectedIds: selectedIds,
                  onSelectionChanged: (id, selected) {
                    setState(() {
                      if (selected) {
                        selectedIds.add(id);
                      } else {
                        selectedIds.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(CheckboxListTile), findsNWidgets(2));

      await tester.tap(find.text(_studentA.studentName));
      await tester.pumpAndSettle();
      expect(selectedIds, {_studentA.id});

      await tester.tap(find.text(_studentA.studentName));
      await tester.pumpAndSettle();
      expect(selectedIds, isEmpty);

      await tester.tap(find.text(_studentA.studentName));
      await tester.tap(find.text(_studentB.studentName));
      await tester.pumpAndSettle();
      expect(selectedIds, {_studentA.id, _studentB.id});
    });
  });

  group('PagedResult parsing', () {
    test('handles items returned as a single map', () {
      final result = PagedResult.fromJson(
        {
          'items': {
            'id': 1,
            'studentName': 'أحمد',
            'fatherPhone': '123',
            'age': 10,
          },
          'page': 1,
          'totalPages': 1,
        },
        AvailableStudent.fromJson,
      );

      expect(result.items, hasLength(1));
      expect(result.items.first.studentName, 'أحمد');
    });

    test('handles nested students pager shape', () {
      final result = PagedResult.fromJson(
        {
          'students': {
            'items': [
              {
                'id': 2,
                'studentName': 'سارة',
                'fatherPhone': '456',
                'age': 9,
              },
            ],
            'page': 1,
            'totalPages': 1,
          },
        },
        AvailableStudent.fromJson,
      );

      expect(result.items, hasLength(1));
      expect(result.items.first.studentName, 'سارة');
    });
  });

  group('AddStudentToCircleScreen', () {
    testWidgets('shows validation when submitting with no selection', (tester) async {
      await _pumpAddScreen(tester, fakeApi: fakeApi);

      await tester.tap(find.text('إضافة للحلقة'));
      await tester.pumpAndSettle();

      expect(find.text('يرجى اختيار طالب واحد على الأقل'), findsOneWidget);
      expect(fakeApi.lastAddedIds, isNull);
    });

    testWidgets('adds selected students to circle via API', (tester) async {
      await _pumpAddScreen(tester, fakeApi: fakeApi);

      await tester.tap(find.text(_studentA.studentName));
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة للحلقة'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeApi.lastAddedIds, [_studentA.id]);
      expect(find.text('تم بنجاح'), findsOneWidget);
      expect(find.text(fakeApi.addMessage), findsOneWidget);

      await tester.tap(find.text('حسناً'));
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('keeps search field visible when search returns no results',
        (tester) async {
      await _pumpAddScreen(tester, fakeApi: fakeApi);

      await tester.enterText(find.byType(TextField), 'غير موجود');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(fakeApi.lastSearchTerm, 'غير موجود');
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('لا توجد نتائج للبحث'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'أحمد');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(fakeApi.lastSearchTerm, 'أحمد');
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(_studentA.studentName), findsOneWidget);
    });

    testWidgets('selection persists while searching', (tester) async {
      await _pumpAddScreen(tester, fakeApi: fakeApi);

      await tester.tap(find.text(_studentA.studentName));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'سارة');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(fakeApi.lastSearchTerm, 'سارة');
      expect(find.text(_studentA.studentName), findsNothing);
      expect(find.text(_studentB.studentName), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final studentACheckbox = tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text(_studentA.studentName),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(studentACheckbox.value, isTrue);
    });

    test('loadMore appends the next page of available students', () async {
      final manyStudents = List<AvailableStudent>.generate(
        25,
        (index) => AvailableStudent(
          id: 1000 + index,
          studentName: 'طالب ${index + 1}',
          fatherPhone: '5000000$index',
          age: 10,
        ),
      );
      fakeApi.setAvailableStudents(manyStudents);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          studentsApiProvider.overrideWithValue(fakeApi),
        ],
      );
      addTearDown(container.dispose);

      final firstPage =
          await container.read(availableStudentsControllerProvider.future);

      expect(firstPage.students, hasLength(20));
      expect(firstPage.page, 1);
      expect(firstPage.hasMore, isTrue);

      await container
          .read(availableStudentsControllerProvider.notifier)
          .loadMore();

      final secondPage = container.read(availableStudentsControllerProvider).value!;

      expect(secondPage.students, hasLength(25));
      expect(secondPage.page, 2);
      expect(secondPage.hasMore, isFalse);
      expect(fakeApi.lastRequestedPage, 2);
    });
  });

  group('StudentsApi remove contract', () {
    test('removeStudentFromCircle captures student id and message', () async {
      final message = await fakeApi.removeStudentFromCircle(_studentA.id);

      expect(fakeApi.lastRemovedId, _studentA.id);
      expect(message, 'تم إزالة الطالب من الحلقة');
    });
  });
}
