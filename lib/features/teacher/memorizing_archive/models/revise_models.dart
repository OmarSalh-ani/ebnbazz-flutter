class IdNameOption {
  const IdNameOption({required this.id, required this.name});

  final int id;
  final String name;

  factory IdNameOption.fromJson(Map<String, dynamic> json) {
    return IdNameOption(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

class RevisePageData {
  const RevisePageData({
    required this.studentId,
    required this.studentName,
    required this.surahs,
  });

  final int studentId;
  final String studentName;
  final List<IdNameOption> surahs;

  factory RevisePageData.fromJson(Map<String, dynamic> json) {
    return RevisePageData(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String? ?? '',
      surahs: (json['surahs'] as List<dynamic>? ?? [])
          .map((e) => IdNameOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReviseMemorizationInput {
  const ReviseMemorizationInput({
    required this.surahId,
    required this.testFrom,
    required this.testTo,
    this.isSaveCompleted = false,
  });

  final int surahId;
  final String testFrom;
  final String testTo;
  final bool isSaveCompleted;

  Map<String, dynamic> toJson() => {
        'surahId': surahId,
        'testFrom': testFrom,
        'testTo': testTo,
        'isSaveCompleted': isSaveCompleted,
      };
}

class ReviseRevisionInput {
  const ReviseRevisionInput({
    required this.testFrom,
    required this.testTo,
    this.isRevisionCompleted = false,
  });

  final String testFrom;
  final String testTo;
  final bool isRevisionCompleted;

  Map<String, dynamic> toJson() => {
        'testFrom': testFrom,
        'testTo': testTo,
        'isRevisionCompleted': isRevisionCompleted,
      };
}

class CreateReviseRequest {
  const CreateReviseRequest({
    this.memorization,
    this.revision,
  });

  final ReviseMemorizationInput? memorization;
  final ReviseRevisionInput? revision;

  Map<String, dynamic> toJson() => {
        if (memorization != null) 'memorization': memorization!.toJson(),
        if (revision != null) 'revision': revision!.toJson(),
      };
}

String formatReviseAyahLabel(String surahName, int ayahNumber) {
  return '$surahName - آية $ayahNumber';
}

CreateReviseRequest buildCreateReviseRequest({
  required String type,
  required int surahId,
  required String surahName,
  required int fromAyah,
  required int toAyah,
}) {
  const typeMemorization = 'حفظ';
  const typeRevision = 'مراجعة';

  final testFrom = formatReviseAyahLabel(surahName, fromAyah);
  final testTo = formatReviseAyahLabel(surahName, toAyah);

  if (type == typeMemorization) {
    return CreateReviseRequest(
      memorization: ReviseMemorizationInput(
        surahId: surahId,
        testFrom: testFrom,
        testTo: testTo,
        isSaveCompleted: true,
      ),
    );
  }

  if (type == typeRevision) {
    return CreateReviseRequest(
      revision: ReviseRevisionInput(
        testFrom: testFrom,
        testTo: testTo,
        isRevisionCompleted: true,
      ),
    );
  }

  throw ArgumentError('Invalid revise type: $type');
}
