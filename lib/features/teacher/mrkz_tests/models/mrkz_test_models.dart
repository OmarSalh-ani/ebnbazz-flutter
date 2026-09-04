class MrkzTestDefinitionOption {
  const MrkzTestDefinitionOption({
    required this.id,
    required this.mtnName,
    required this.totalScore,
    required this.errorWeight,
    this.adminNotes,
  });

  final int id;
  final String mtnName;
  final double totalScore;
  final double errorWeight;
  final String? adminNotes;

  factory MrkzTestDefinitionOption.fromJson(Map<String, dynamic> json) {
    return MrkzTestDefinitionOption(
      id: json['id'] as int? ?? 0,
      mtnName: json['mtnName'] as String? ?? '',
      totalScore: _toDouble(json['totalScore']),
      errorWeight: _toDouble(json['errorWeight']),
      adminNotes: json['notes'] as String?,
    );
  }
}

class MrkzTestResultRecord {
  const MrkzTestResultRecord({
    required this.resultId,
    required this.testDefinitionId,
    required this.mtnName,
    required this.totalScore,
    required this.errorWeight,
    required this.mistakeCount,
    required this.finalScore,
    required this.grade,
    this.notes,
    required this.testDate,
  });

  final int resultId;
  final int testDefinitionId;
  final String mtnName;
  final double totalScore;
  final double errorWeight;
  final int mistakeCount;
  final double finalScore;
  final String grade;
  final String? notes;
  final String testDate;

  String get displayDate {
    if (testDate.isEmpty) return '';
    final parsed = DateTime.tryParse(testDate);
    if (parsed == null) return testDate;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  String get displayFinalScore => _formatScore(finalScore);

  factory MrkzTestResultRecord.fromJson(Map<String, dynamic> json) {
    return MrkzTestResultRecord(
      resultId: json['resultId'] as int? ?? 0,
      testDefinitionId: json['testDefinitionId'] as int? ?? 0,
      mtnName: json['mtnName'] as String? ?? '',
      totalScore: _toDouble(json['totalScore']),
      errorWeight: _toDouble(json['errorWeight']),
      mistakeCount: json['mistakeCount'] as int? ?? 0,
      finalScore: _toDouble(json['finalScore']),
      grade: json['grade'] as String? ?? '',
      notes: json['notes'] as String?,
      testDate: json['testDate'] as String? ?? '',
    );
  }
}

class MrkzTestsPage {
  const MrkzTestsPage({
    required this.studentId,
    required this.studentName,
    required this.tests,
  });

  final int studentId;
  final String studentName;
  final List<MrkzTestResultRecord> tests;

  factory MrkzTestsPage.fromJson(Map<String, dynamic> json) {
    final testsJson = json['tests'] as List<dynamic>? ?? [];
    return MrkzTestsPage(
      studentId: json['studentId'] as int? ?? 0,
      studentName: json['studentName'] as String? ?? '',
      tests: testsJson
          .whereType<Map>()
          .map((e) => MrkzTestResultRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SaveMrkzTestResultRequest {
  const SaveMrkzTestResultRequest({
    required this.testDefinitionId,
    required this.mistakeCount,
    this.notes,
  });

  final int testDefinitionId;
  final int mistakeCount;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'testDefinitionId': testDefinitionId,
        'mistakeCount': mistakeCount,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

double calculateMrkzFinalScore({
  required double totalScore,
  required int mistakeCount,
  required double errorWeight,
}) {
  final deducted = mistakeCount * errorWeight;
  final result = totalScore - deducted;
  if (result < 0) return 0;
  return double.parse(result.toStringAsFixed(2));
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
