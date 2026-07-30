class TestCertificate {
  const TestCertificate({
    required this.testId,
    required this.studentName,
    required this.circleName,
    required this.testPeriod,
    required this.hizbCells,
    required this.memorizationScore,
    required this.tajweedScore,
    required this.revisionScore,
    required this.totalScore,
    required this.grade,
    required this.testDate,
  });

  final int testId;
  final String studentName;
  final String circleName;
  final String testPeriod;
  final List<String> hizbCells;
  final String memorizationScore;
  final String tajweedScore;
  final String revisionScore;
  final String totalScore;
  final String grade;
  final String testDate;

  factory TestCertificate.fromJson(Map<String, dynamic> json) {
    final hizbJson = json['hizbCells'] as List<dynamic>? ?? [];
    return TestCertificate(
      testId: json['testId'] as int? ?? 0,
      studentName: json['studentName'] as String? ?? '',
      circleName: json['circleName'] as String? ?? '',
      testPeriod: json['testPeriod'] as String? ?? 'الفصل الأول',
      hizbCells: hizbJson.map((e) => e.toString()).toList(),
      memorizationScore: json['memorizationScore'] as String? ?? '',
      tajweedScore: json['tajweedScore'] as String? ?? '',
      revisionScore: json['revisionScore'] as String? ?? '',
      totalScore: json['totalScore'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      testDate: json['testDate'] as String? ?? '',
    );
  }
}

class TestCertificatePeriods {
  static const periods = [
    'الفصل الأول',
    'الفصل الثاني',
    'الفصل الثالث',
  ];
}
