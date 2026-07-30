import 'package:masged_parent_app/core/utils/media_url_helper.dart';

class StudentsStatistics {
  const StudentsStatistics({
    required this.totalStudents,
    required this.presentStudents,
    required this.absentStudents,
    required this.departedStudents,
  });

  final int totalStudents;
  final int presentStudents;
  final int absentStudents;
  final int departedStudents;

  factory StudentsStatistics.fromJson(Map<String, dynamic> json) {
    return StudentsStatistics(
      totalStudents: json['totalStudents'] as int? ?? 0,
      presentStudents: json['presentStudents'] as int? ?? 0,
      absentStudents: json['absentStudents'] as int? ?? 0,
      departedStudents: json['departedStudents'] as int? ?? 0,
    );
  }
}

class DashboardPageData {
  const DashboardPageData({
    required this.teacherName,
    required this.circleName,
    required this.isWorkDayToday,
    required this.statistics,
    required this.unreadAdminNotesCount,
    required this.students,
  });

  final String teacherName;
  final String circleName;
  final bool isWorkDayToday;
  final StudentsStatistics statistics;
  final int unreadAdminNotesCount;
  final List<StudentListItem> students;

  factory DashboardPageData.fromJson(Map<String, dynamic> json) {
    final studentsJson = json['students'] as List<dynamic>? ?? [];

    return DashboardPageData(
      teacherName: json['teacherName'] as String? ?? '',
      circleName: json['circleName'] as String? ?? '',
      isWorkDayToday: json['isWorkDayToday'] as bool? ?? true,
      statistics: StudentsStatistics.fromJson(
        json['statistics'] as Map<String, dynamic>? ?? {},
      ),
      unreadAdminNotesCount: json['unreadAdminNotesCount'] as int? ?? 0,
      students: studentsJson
          .map((e) => StudentListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentListItem {
  const StudentListItem({
    required this.id,
    required this.name,
    required this.age,
    required this.group,
    required this.planLevelName,
    required this.isPresentToday,
    required this.departureStatusToday,
    required this.departureTimeToday,
    required this.fatherPhone,
    this.imageUrl,
    this.isSpecial = false,
    this.isElite = false,
    this.hasHealthCondition = false,
    this.hasLearningDifficulties = false,
    this.warningCount = 0,
    this.parentQuestionsCount = 0,
  });

  final int id;
  final String name;
  final int age;
  final String group;
  final String planLevelName;
  final String isPresentToday;
  final String departureStatusToday;
  final String departureTimeToday;
  final String fatherPhone;
  final String? imageUrl;
  final bool isSpecial;
  final bool isElite;
  final bool hasHealthCondition;
  final bool hasLearningDifficulties;
  final int warningCount;
  final int parentQuestionsCount;

  /// Badge text for today's attendance (includes departure time when applicable).
  String get todayStatusLabel {
    if (isPresentToday == 'منصرف') {
      if (departureTimeToday.isNotEmpty) {
        return 'منصرف $departureTimeToday';
      }
      return 'منصرف';
    }
    return isPresentToday;
  }

  bool get hasDepartedToday =>
      isPresentToday == 'منصرف' || departureStatusToday == 'منصرف';

  factory StudentListItem.fromJson(Map<String, dynamic> json) {
    return StudentListItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      group: json['group'] as String? ?? '',
      planLevelName: json['planLevelName'] as String? ?? '',
      isPresentToday: json['isPresentToday'] as String? ?? '',
      departureStatusToday: json['departureStatusToday'] as String? ?? '',
      departureTimeToday: json['departureTimeToday'] as String? ?? '',
      fatherPhone: json['fatherPhone'] as String? ?? '',
      imageUrl: MediaUrlHelper.resolve(json['imageUrl'] as String?),
      isSpecial: json['isSpecial'] as bool? ?? false,
      isElite: json['isElite'] as bool? ?? false,
      hasHealthCondition: json['hasHealthCondition'] as bool? ?? false,
      hasLearningDifficulties: json['hasLearningDifficulties'] as bool? ?? false,
      warningCount: json['warningCount'] as int? ?? 0,
      parentQuestionsCount: json['parentQuestionsCount'] as int? ?? 0,
    );
  }
}
