/// Maps [GET /api/students/:id/quran-assignment].
class StudentQuranAssignment {
  final int memorizeSurahId;
  final String memorizeSurahNameArabic;
  final int memorizeFromAyah;
  final int memorizeToAyah;
  final int? reviseSurahId;
  final String? reviseSurahNameArabic;
  final int reviseFromAyah;
  final int reviseToAyah;

  StudentQuranAssignment({
    required this.memorizeSurahId,
    required this.memorizeSurahNameArabic,
    required this.memorizeFromAyah,
    required this.memorizeToAyah,
    this.reviseSurahId,
    this.reviseSurahNameArabic,
    required this.reviseFromAyah,
    required this.reviseToAyah,
  });

  factory StudentQuranAssignment.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v == null) return fallback;
      return int.tryParse(v.toString()) ?? fallback;
    }

    final reviseRaw = json['reviseSurahId'];
    final reviseParsed = reviseRaw == null ? 0 : readInt(reviseRaw, 0);

    return StudentQuranAssignment(
      memorizeSurahId: readInt(json['memorizeSurahId'], 1),
      memorizeSurahNameArabic:
          (json['memorizeSurahNameArabic'] ?? '').toString(),
      memorizeFromAyah: readInt(json['memorizeFromAyah'], 1),
      memorizeToAyah: readInt(json['memorizeToAyah'], 1),
      reviseSurahId: reviseParsed == 0 ? null : reviseParsed,
      reviseSurahNameArabic: json['reviseSurahNameArabic']?.toString(),
      reviseFromAyah: readInt(json['reviseFromAyah'], 0),
      reviseToAyah: readInt(json['reviseToAyah'], 0),
    );
  }

  bool get hasRevise =>
      reviseSurahId != null &&
      reviseSurahId! > 0 &&
      reviseFromAyah > 0 &&
      reviseToAyah > 0 &&
      ((reviseSurahNameArabic ?? '').trim().isNotEmpty);
}