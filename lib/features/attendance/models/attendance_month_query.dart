/// Query parameters for server-side month filtering.
class AttendanceMonthQuery {
  final String studentId;
  final int year;
  final int month;

  const AttendanceMonthQuery({
    required this.studentId,
    required this.year,
    required this.month,
  });

  factory AttendanceMonthQuery.currentMonth(String studentId) {
    final now = DateTime.now();
    return AttendanceMonthQuery(
      studentId: studentId,
      year: now.year,
      month: now.month,
    );
  }

  AttendanceMonthQuery copyWith({int? year, int? month}) {
    return AttendanceMonthQuery(
      studentId: studentId,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }

  DateTime get monthDate => DateTime(year, month);

  @override
  bool operator ==(Object other) {
    return other is AttendanceMonthQuery &&
        other.studentId == studentId &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(studentId, year, month);
}
