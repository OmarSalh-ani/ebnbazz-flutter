class MrkzTestsPage {
  const MrkzTestsPage({
    required this.studentId,
    required this.studentName,
    required this.tests,
  });

  final int studentId;
  final String studentName;
  final List<MrkzTestRecord> tests;

  factory MrkzTestsPage.fromJson(Map<String, dynamic> json) {
    final testsJson = json['tests'] as List<dynamic>? ?? [];
    return MrkzTestsPage(
      studentId: json['studentId'] as int? ?? 0,
      studentName: json['studentName'] as String? ?? '',
      tests: testsJson
          .whereType<Map>()
          .map((e) => MrkzTestRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class MrkzTestRecord {
  const MrkzTestRecord({
    required this.testId,
    required this.testDate,
    required this.averageScore,
    required this.grade,
    required this.items,
  });

  final int testId;
  final String testDate;
  final double averageScore;
  final String grade;
  final List<MrkzTestItem> items;

  String get displayDate {
    if (testDate.isEmpty) return '';
    final parsed = DateTime.tryParse(testDate);
    if (parsed == null) return testDate;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  String get mutoonSummary {
    final names = items.map((i) => i.mtnName).where((n) => n.isNotEmpty);
    if (names.isEmpty) return '—';
    return names.join('، ');
  }

  String get displayAverage => _formatScore(averageScore);

  factory MrkzTestRecord.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return MrkzTestRecord(
      testId: json['testId'] as int? ?? 0,
      testDate: json['testDate'] as String? ?? '',
      averageScore: _toDouble(json['averageScore']),
      grade: json['grade'] as String? ?? '',
      items: itemsJson
          .whereType<Map>()
          .map((e) => MrkzTestItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class MrkzTestItem {
  const MrkzTestItem({
    required this.mtnName,
    required this.score,
    this.itemOrder = 0,
  });

  final String mtnName;
  final double score;
  final int itemOrder;

  String get displayScore => _formatScore(score);

  Map<String, dynamic> toJson() => {
        'mtnName': mtnName,
        'score': score,
      };

  factory MrkzTestItem.fromJson(Map<String, dynamic> json) {
    return MrkzTestItem(
      mtnName: json['mtnName'] as String? ?? '',
      score: _toDouble(json['score']),
      itemOrder: json['itemOrder'] as int? ?? 0,
    );
  }
}

class SaveMrkzTestRequest {
  const SaveMrkzTestRequest({required this.items, this.testDate});

  final DateTime? testDate;
  final List<MrkzTestItem> items;

  Map<String, dynamic> toJson() => {
        if (testDate != null) 'testDate': testDate!.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class MrkzTestGrades {
  static String calculate(double averageScore) {
    if (averageScore >= 90) return 'ممتاز';
    if (averageScore >= 80) return 'جيد جدا';
    if (averageScore >= 70) return 'جيد';
    if (averageScore >= 60) return 'متوسط';
    return 'ضعيف';
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String _formatScore(double score) {
  if (score == score.roundToDouble()) {
    return score.round().toString();
  }
  return score.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}
