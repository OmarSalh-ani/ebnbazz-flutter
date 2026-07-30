import '../../../core/utils/media_url_helper.dart';

enum ChildStatus { absent, inMasged, left, vacation }

class ChildModel {
  final String id;
  final String name;
  final String level;
  final String group;
  final String? avatarUrl;
  final int attendancePercent;
  final String nextSession;
  final String? logTime;
  final String? departureTime;
  final String? notes;
  final String? teacherId;
  final String? teacherName;
  final ChildStatus status;
  final Map<String, bool?>? weeklyAttendance;
  final DateTime? birthDate;
  final String? memorizationProgress; // e.g., "سورة البقرة - آية 150"
  final String? revisionProgress; // e.g., "جزء عم كامل"

  final String? fullName; // الاسم الرباعي
  final String? address;
  final String? parentName;
  final String? phoneNumber;
  final String? parentMaritalStatus; // متزوج، متوفي، مطلق، أعزب
  final bool? hasHealthCondition;
  final String? healthConditionDetails;
  final bool? hasLearningDifficulties;
  final String? learningDifficultiesDetails;
  final int absentDaysThisMonth;
  final int lateCount;

  const ChildModel({
    required this.id,
    required this.name,
    required this.level,
    required this.group,
    this.avatarUrl,
    required this.attendancePercent,
    required this.nextSession,
    required this.status,
    this.logTime,
    this.departureTime,
    this.notes,
    this.teacherId,
    this.teacherName,
    this.weeklyAttendance,
    this.birthDate,
    this.memorizationProgress,
    this.revisionProgress,
    this.fullName,
    this.address,
    this.parentName,
    this.phoneNumber,
    this.parentMaritalStatus,
    this.hasHealthCondition,
    this.healthConditionDetails,
    this.hasLearningDifficulties,
    this.learningDifficultiesDetails,
    this.absentDaysThisMonth = 0,
    this.lateCount = 0,
  });

  String get firstName => name.trim().split(' ').first;

  static String? _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v != null) return v.toString();
    }
    return null;
  }

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'absent').toLowerCase();
    ChildStatus status;
    switch (statusStr) {
      case 'inmasged':
      case 'in_masged':
        status = ChildStatus.inMasged;
        break;
      case 'left':
        status = ChildStatus.left;
        break;
      case 'vacation':
        status = ChildStatus.vacation;
        break;
      default:
        status = ChildStatus.absent;
    }

    Map<String, bool?>? weeklyAttendance;
    final weekly = json['weeklyAttendance'];
    if (weekly is Map) {
      weeklyAttendance = weekly.map(
        (key, value) => MapEntry(
          key.toString(),
          value == null ? null : value == true,
        ),
      );
    }

    return ChildModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      level: json['level'] as String? ?? '',
      group: json['group'] as String? ?? '',
      avatarUrl: MediaUrlHelper.resolve(json['avatarUrl'] as String?),
      attendancePercent: json['attendancePercent'] as int? ?? 0,
      nextSession: json['nextSession'] as String? ?? '',
      status: status,
      logTime: json['logTime'] as String? ?? json['attendTime'] as String?,
      departureTime: json['departureTime'] as String?,
      notes: json['notes'] as String?,
      teacherId: _pickString(json, const ['teacherId', 'TeacherId']),
      teacherName: _pickString(json, const ['teacherName', 'TeacherName']),
      weeklyAttendance: weeklyAttendance,
      fullName: json['fullName'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'].toString())
          : null,
      address: json['address'] as String?,
      parentName: json['parentName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      parentMaritalStatus: json['parentMaritalStatus'] as String?,
      hasHealthCondition: json['hasHealthCondition'] as bool?,
      healthConditionDetails: json['healthConditionDetails'] as String?,
      hasLearningDifficulties: json['hasLearningDifficulties'] as bool?,
      learningDifficultiesDetails:
          json['learningDifficultiesDetails'] as String?,
      memorizationProgress: json['memorizationProgress'] as String?,
      revisionProgress: json['revisionProgress'] as String?,
      absentDaysThisMonth: json['absentDaysThisMonth'] as int? ?? 0,
      lateCount: json['lateCount'] as int? ??
          json['LateCount'] as int? ??
          0,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'fullName': fullName ?? name,
        'birthDate': birthDate?.toIso8601String(),
        'address': address,
        'parentName': parentName,
        'phone': phoneNumber,
        'maritalStatus': parentMaritalStatus,
        'hasHealthCondition': hasHealthCondition,
        'healthDetails': healthConditionDetails,
        'hasLearningDifficulties': hasLearningDifficulties,
        'learningDifficultiesDetails': learningDifficultiesDetails,
      };

}
