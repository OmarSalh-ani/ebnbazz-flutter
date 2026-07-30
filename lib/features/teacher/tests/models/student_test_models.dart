class StudentTestsPage {
  const StudentTestsPage({
    required this.studentId,
    required this.studentName,
    required this.tests,
  });

  final int studentId;
  final String studentName;
  final List<StudentTestListItem> tests;

  factory StudentTestsPage.fromJson(Map<String, dynamic> json) {
    final testsJson = json['tests'] as List<dynamic>? ?? [];
    return StudentTestsPage(
      studentId: json['studentId'] as int? ?? 0,
      studentName: json['studentName'] as String? ?? '',
      tests: testsJson
          .map((e) => StudentTestListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentTestListItem {
  const StudentTestListItem({
    required this.testId,
    required this.testName,
    required this.surahName,
    required this.hezbNumber,
    required this.from,
    required this.to,
    required this.testDegree,
    this.notes,
  });

  final int testId;
  final String testName;
  final String surahName;
  final String hezbNumber;
  final String from;
  final String to;
  final String testDegree;
  final String? notes;

  factory StudentTestListItem.fromJson(Map<String, dynamic> json) {
    return StudentTestListItem(
      testId: json['testId'] as int? ?? 0,
      testName: json['testName'] as String? ?? '',
      surahName: json['surahName'] as String? ?? '',
      hezbNumber: json['hezbNumber'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      testDegree: json['testDegree'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}

class StudentTestDetail {
  const StudentTestDetail({
    required this.testId,
    required this.studentId,
    required this.testDate,
    required this.finalResult,
    required this.surahName,
    required this.hezbNumber,
    required this.fromSurah,
    required this.toSurah,
    this.notes,
    this.memorizationScore,
    this.tajweedScore,
    this.revisionScore,
    this.totalScore,
    this.grade,
  });

  final int testId;
  final int studentId;
  final String testDate;
  final String finalResult;
  final String surahName;
  final String hezbNumber;
  final String fromSurah;
  final String toSurah;
  final String? notes;
  final int? memorizationScore;
  final int? tajweedScore;
  final int? revisionScore;
  final int? totalScore;
  final String? grade;

  int get displayMemorization => memorizationScore ?? 0;
  int get displayTajweed => tajweedScore ?? 0;
  int get displayRevision => revisionScore ?? 0;

  int get displayPerformance => revisionScore ?? 0;

  int get displayTotal {
    if (totalScore != null) return totalScore!;
    final parsed = int.tryParse(finalResult.replaceAll(',', ''));
    return parsed ?? 0;
  }

  String get displayGrade => grade ?? StudentTestGrades.calculate(displayTotal);

  String get displayDate {
    if (testDate.isEmpty) return '';
    final parsed = DateTime.tryParse(testDate);
    if (parsed == null) return testDate;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  List<String> get hezbCells => StudentTestHezb.parse(hezbNumber);

  factory StudentTestDetail.fromJson(Map<String, dynamic> json) {
    return StudentTestDetail(
      testId: json['testId'] as int? ?? 0,
      studentId: json['studentId'] as int? ?? 0,
      testDate: json['testDate'] as String? ?? '',
      finalResult: json['finalResult'] as String? ?? '',
      surahName: json['surahName'] as String? ?? '',
      hezbNumber: json['hezbNumber'] as String? ?? '',
      fromSurah: json['fromSurah'] as String? ?? '',
      toSurah: json['toSurah'] as String? ?? '',
      notes: json['notes'] as String?,
      memorizationScore: _toInt(json['memorizationScore']),
      tajweedScore: _toInt(json['tajweedScore']),
      revisionScore: _toInt(json['revisionScore']),
      totalScore: _toInt(json['totalScore']),
      grade: json['grade'] as String?,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}

class SaveStudentTestRequest {
  const SaveStudentTestRequest({
    this.testDate,
    this.surahName,
    this.hezbNumber,
    this.notes,
    this.memorizationScore,
    this.tajweedScore,
    this.revisionScore,
    this.totalScore,
    this.grade,
  });

  final DateTime? testDate;
  final String? surahName;
  final String? hezbNumber;
  final String? notes;
  final int? memorizationScore;
  final int? tajweedScore;
  /// Performance score (الأداء) — stored as revisionScore in the API.
  final int? revisionScore;
  final int? totalScore;
  final String? grade;

  Map<String, dynamic> toJson() => {
        if (testDate != null) 'testDate': testDate!.toIso8601String(),
        if (surahName != null) 'surahName': surahName,
        if (hezbNumber != null) 'hezbNumber': hezbNumber,
        if (notes != null) 'notes': notes,
        if (memorizationScore != null) 'memorizationScore': memorizationScore,
        if (tajweedScore != null) 'tajweedScore': tajweedScore,
        if (revisionScore != null) 'revisionScore': revisionScore,
        if (totalScore != null) 'totalScore': totalScore,
        if (grade != null) 'grade': grade,
      };
}

class StudentTestHezb {
  static const int cellCount = 8;

  static List<String> parse(String? value) {
    final cells = List<String>.filled(cellCount, '');
    if (value == null || value.trim().isEmpty) return cells;

    final parts = value.split(',');
    for (var i = 0; i < cellCount && i < parts.length; i++) {
      cells[i] = parts[i].trim();
    }
    return cells;
  }

  static String join(List<String> cells) {
    return cells
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .join(',');
  }
}

class StudentTestGrades {
  static String calculate(int totalScore) {
    if (totalScore >= 90) return 'ممتاز';
    if (totalScore >= 80) return 'جيد جدا';
    if (totalScore >= 70) return 'جيد';
    if (totalScore >= 60) return 'متوسط';
    return 'ضعيف';
  }
}
