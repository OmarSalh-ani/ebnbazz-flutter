class ScheduleSlotModel {
  final int studentId;
  final String studentName;
  final String circleName;
  final List<String> weekdaysArabic;

  ScheduleSlotModel({
    required this.studentId,
    required this.studentName,
    required this.circleName,
    required this.weekdaysArabic,
  });

  factory ScheduleSlotModel.fromJson(Map<String, dynamic> json) {
    final weekdays = json['weekdaysArabic'];
    return ScheduleSlotModel(
      studentId: json['studentId'] as int,
      studentName: (json['studentName'] ?? '').toString(),
      circleName: (json['circleName'] ?? '').toString(),
      weekdaysArabic: weekdays is List
          ? weekdays.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
