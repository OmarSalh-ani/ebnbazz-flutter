import 'dart:developer' as developer;
import 'package:masged_parent_app/features/teacher/dashboard/models/dashboard_models.dart';
import 'package:masged_parent_app/features/teacher/plans/models/student_plan_models.dart';

enum VoiceCommandType {
  attendance,
  attendanceExcept,
  departure,
  assignPlan,
  unrecognized,
}

class StudentMatchCandidate {
  const StudentMatchCandidate({
    required this.student,
    required this.score,
    required this.isExact,
  });

  final StudentListItem student;
  final int score;
  final bool isExact;
}

class VoiceCommandResult {
  final VoiceCommandType type;
  final String rawText;
  final String normalizedText;
  
  // Specific for assignPlan:
  final String? studentName;
  final String? startSurahName;
  final int? startFromAyah;
  final int? startToAyah;
  final String? endSurahName;
  final int? endFromAyah;
  final int? endToAyah;

  /// Raw names blob after "ما عدا" / "إلا" (attendanceExcept).
  final String? excludedNamesBlob;
  final List<String> excludedNamePhrases;

  VoiceCommandResult({
    required this.type,
    required this.rawText,
    required this.normalizedText,
    this.studentName,
    this.startSurahName,
    this.startFromAyah,
    this.startToAyah,
    this.endSurahName,
    this.endFromAyah,
    this.endToAyah,
    this.excludedNamesBlob,
    this.excludedNamePhrases = const [],
  });

  @override
  String toString() {
    return 'VoiceCommandResult(type: $type, student: $studentName, excluded: $excludedNamePhrases, startSurah: $startSurahName, startAyah: $startFromAyah-$startToAyah, endSurah: $endSurahName, endAyah: $endFromAyah-$endToAyah)';
  }
}

class AttendanceExceptResolution {
  const AttendanceExceptResolution({
    required this.excludedStudents,
    required this.unmatchedPhrases,
    required this.needsManualSelection,
  });

  final List<StudentListItem> excludedStudents;
  final List<String> unmatchedPhrases;
  final bool needsManualSelection;
}

class VoiceCommandExample {
  const VoiceCommandExample({
    required this.category,
    required this.phrase,
    required this.description,
  });

  final String category;
  final String phrase;
  final String description;
}

class VoiceCommandService {
  VoiceCommandService._();

  static const List<VoiceCommandExample> commandExamples = [
    VoiceCommandExample(
      category: 'تحضير الحضور',
      phrase: 'تحضير جميع الطلاب',
      description: 'تحضير جميع الطلاب في الحلقة',
    ),
    VoiceCommandExample(
      category: 'تحضير الحضور',
      phrase: 'تحضير الطلاب',
      description: 'تحضير جميع الطلاب في الحلقة',
    ),
    VoiceCommandExample(
      category: 'تحضير مع استثناء',
      phrase: 'تحضير جميع الطلاب ما عدا أحمد ومحمد',
      description: 'تحضير الجميع مع بقاء المذكورين غائبين',
    ),
    VoiceCommandExample(
      category: 'تحضير مع استثناء',
      phrase: 'تحضير كل الطلاب إلا علي',
      description: 'تحضير الجميع ما عدا علي',
    ),
    VoiceCommandExample(
      category: 'الانصراف',
      phrase: 'صرف الطلاب',
      description: 'تسجيل انصراف جميع الطلاب',
    ),
    VoiceCommandExample(
      category: 'الانصراف',
      phrase: 'انصراف الطلاب',
      description: 'تسجيل انصراف جميع الطلاب',
    ),
    VoiceCommandExample(
      category: 'إنشاء خطة',
      phrase:
          'خطة لأحمد تبدأ من سورة البقرة الآية 1 للآية 5 وتنتهي بسورة النساء الآية 1 للآية 3',
      description:
          'إنشاء خطة حفظ للطالب من سورة البقرة (1–5) إلى سورة النساء (1–3)',
    ),
  ];

  static String normalizeArabic(String text) {
    var normalized = text.replaceAll(RegExp(r'[\u064B-\u0652]'), ''); // Remove diacritics
    normalized = normalized.replaceAll(RegExp(r'[أإآ]'), 'ا'); // Unify Alef
    normalized = normalized.replaceAll(RegExp(r'ة'), 'ه'); // Unify Teh Marbuta
    normalized = normalized.replaceAll(RegExp(r'ى'), 'ي'); // Unify Ya
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim(); // Normalize whitespace
    return normalized;
  }

  /// Parses spoken Arabic text into a structured VoiceCommandResult.
  static VoiceCommandResult parseCommand(String text) {
    final normalized = normalizeArabic(text);
    developer.log('Parsing voice command. Raw: "$text", Normalized: "$normalized"');

    // 1. Attendance for all except named students (must run before plain attendance)
    if (normalized.contains('تحضير') &&
        (normalized.contains('طلاب') ||
            normalized.contains('الطلاب') ||
            normalized.contains('الجميع') ||
            normalized.contains('كل'))) {
      final exceptMatch = RegExp(
        r'تحضير\s+(?:(?:جميع|كل)\s+)?(?:ال)?طلاب\s+(?:ما\s*عدا|ماعدا|ماعادا|إلا|الا)\s*(?:الطلاب\s+)?(.+)$',
        caseSensitive: false,
      ).firstMatch(normalized);

      if (exceptMatch != null) {
        final namesBlob = exceptMatch.group(1)?.trim() ?? '';
        return VoiceCommandResult(
          type: VoiceCommandType.attendanceExcept,
          rawText: text,
          normalizedText: normalized,
          excludedNamesBlob: namesBlob,
          excludedNamePhrases: splitExcludedNamePhrases(namesBlob),
        );
      }

      return VoiceCommandResult(
        type: VoiceCommandType.attendance,
        rawText: text,
        normalizedText: normalized,
      );
    }

    // 2. Check for bulk departure
    if ((normalized.contains('صرف') || normalized.contains('انصراف')) && (normalized.contains('طلاب') || normalized.contains('الطلاب'))) {
      return VoiceCommandResult(
        type: VoiceCommandType.departure,
        rawText: text,
        normalizedText: normalized,
      );
    }

    // 3. Check for student plan
    if (normalized.contains('خطه')) {
      // Regex pattern to capture the parts:
      // Group 1: Student Name
      // Group 2: Start Surah
      // Group 3: Start from Ayah
      // Group 4: Start to Ayah
      // Group 5: End Surah
      // Group 6: End from Ayah
      // Group 7: End to Ayah
      final regex = RegExp(
        r'خطه\s+(?:ل|لـ)?\s*(.*?)\s+تبدا\s+من\s+(?:سوره\s+)?(.*?)\s+(?:الايه|اية)\s+(\d+)\s+(?:للايه|الي\s+(?:الايه|اية)|الي)\s+(\d+)\s+(?:وتنتهي|تنتهي)\s+(?:بسوره|ب)?\s*(.*?)\s+(?:الايه|اية)\s+(\d+)\s+(?:للايه|الي\s+(?:الايه|اية)|الي)\s+(\d+)',
        caseSensitive: false,
      );

      final match = regex.firstMatch(normalized);
      if (match != null) {
        final studentName = match.group(1)?.trim();
        final startSurah = match.group(2)?.trim();
        final startFrom = int.tryParse(match.group(3) ?? '');
        final startTo = int.tryParse(match.group(4) ?? '');
        final endSurah = match.group(5)?.trim();
        final endFrom = int.tryParse(match.group(6) ?? '');
        final endTo = int.tryParse(match.group(7) ?? '');

        return VoiceCommandResult(
          type: VoiceCommandType.assignPlan,
          rawText: text,
          normalizedText: normalized,
          studentName: studentName,
          startSurahName: startSurah,
          startFromAyah: startFrom,
          startToAyah: startTo,
          endSurahName: endSurah,
          endFromAyah: endFrom,
          endToAyah: endTo,
        );
      }
    }

    return VoiceCommandResult(
      type: VoiceCommandType.unrecognized,
      rawText: text,
      normalizedText: normalized,
    );
  }

  /// Splits the spoken names section after "ما عدا" into individual name phrases.
  static List<String> splitExcludedNamePhrases(String blob) {
    var normalized = normalizeArabic(blob).trim();
    if (normalized.isEmpty) return [];

    normalized = normalized.replaceFirst(RegExp(r'^الطلاب\s+'), '');
    normalized = normalized.replaceFirst(RegExp(r'^طلاب\s+'), '');

    return normalized
        .split(RegExp(r'\s+و\s+|،|,'))
        .map((s) => s.trim())
        .where((s) => s.length >= 2)
        .toList();
  }

  /// Resolves which students should stay absent (excluded from bulk attendance).
  static AttendanceExceptResolution resolveExcludedStudents(
    List<StudentListItem> students, {
    required String namesBlob,
    required List<String> phrases,
  }) {
    if (students.isEmpty) {
      return const AttendanceExceptResolution(
        excludedStudents: [],
        unmatchedPhrases: [],
        needsManualSelection: true,
      );
    }

    final excludedById = <int, StudentListItem>{};
    final unmatched = <String>[];

    var remaining = normalizeArabic(namesBlob).trim();
    remaining = remaining.replaceFirst(RegExp(r'^الطلاب\s+'), '');
    remaining = remaining.replaceFirst(RegExp(r'^طلاب\s+'), '');

    final sortedByNameLength = [...students]
      ..sort(
        (a, b) => normalizeArabic(b.name).length
            .compareTo(normalizeArabic(a.name).length),
      );

    for (final student in sortedByNameLength) {
      final normName = normalizeArabic(student.name).trim();
      if (normName.length < 3) continue;
      if (remaining.contains(normName)) {
        excludedById[student.id] = student;
        remaining = remaining
            .replaceAll(normName, ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }
    }

    final phrasesToProcess = phrases.isNotEmpty
        ? phrases
        : (remaining.length >= 2 ? [remaining] : <String>[]);

    for (final phrase in phrasesToProcess) {
      final trimmed = phrase.trim();
      if (trimmed.isEmpty) continue;

      final candidates = findStudentCandidates(students, trimmed, maxResults: 4);
      if (candidates.isNotEmpty && isConfidentSingleMatch(candidates)) {
        excludedById[candidates.first.student.id] = candidates.first.student;
      } else {
        unmatched.add(trimmed);
      }
    }

    final needsManual = unmatched.isNotEmpty ||
        (excludedById.isEmpty &&
            (namesBlob.trim().isNotEmpty || phrases.isNotEmpty));

    return AttendanceExceptResolution(
      excludedStudents: excludedById.values.toList(),
      unmatchedPhrases: unmatched,
      needsManualSelection: needsManual,
    );
  }

  /// Similar students to pick as absent when speech names are unclear.
  static List<StudentMatchCandidate> suggestAbsentStudents(
    List<StudentListItem> students,
    List<String> unmatchedPhrases,
    List<StudentListItem> alreadyExcluded,
  ) {
    final seen = {for (final s in alreadyExcluded) s.id};
    final suggestions = <StudentMatchCandidate>[];

    for (final phrase in unmatchedPhrases) {
      for (final candidate
          in findStudentCandidates(students, phrase, maxResults: 6)) {
        if (seen.add(candidate.student.id)) {
          suggestions.add(candidate);
        }
      }
    }

    if (suggestions.isEmpty) {
      for (final phrase in unmatchedPhrases) {
        final tokens = phrase
            .split(' ')
            .where((t) => t.trim().length >= 2)
            .toList();
        for (final token in tokens) {
          for (final candidate
              in findStudentCandidates(students, token, maxResults: 4)) {
            if (seen.add(candidate.student.id)) {
              suggestions.add(candidate);
            }
          }
        }
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  /// Ranked student match for voice disambiguation.
  static List<StudentMatchCandidate> findStudentCandidates(
    List<StudentListItem> students,
    String spokenName, {
    int maxResults = 6,
  }) {
    final normSpoken = normalizeArabic(spokenName).trim();
    if (normSpoken.isEmpty || students.isEmpty) return [];

    final spokenTokens =
        normSpoken.split(' ').where((t) => t.isNotEmpty).toList();
    if (spokenTokens.isEmpty) return [];

    final requiredScore = spokenTokens.length > 1 ? 2 : 1;
    final candidates = <StudentMatchCandidate>[];

    for (final student in students) {
      final normStudent = normalizeArabic(student.name).trim();
      if (normStudent.isEmpty) continue;

      if (normStudent == normSpoken) {
        candidates.add(
          StudentMatchCandidate(student: student, score: 100, isExact: true),
        );
        continue;
      }

      if (normStudent.contains(normSpoken) || normSpoken.contains(normStudent)) {
        candidates.add(
          StudentMatchCandidate(student: student, score: 80, isExact: false),
        );
        continue;
      }

      final studentTokens =
          normStudent.split(' ').where((t) => t.isNotEmpty).toList();
      var score = 0;
      for (final token in spokenTokens) {
        if (studentTokens.contains(token)) {
          score++;
        }
      }

      if (score >= requiredScore) {
        candidates.add(
          StudentMatchCandidate(student: student, score: score, isExact: false),
        );
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final seen = <int>{};
    final unique = <StudentMatchCandidate>[];
    for (final c in candidates) {
      if (seen.add(c.student.id)) {
        unique.add(c);
      }
      if (unique.length >= maxResults) break;
    }
    return unique;
  }

  /// True when a single student can be shown for confirmation without picking.
  static bool isConfidentSingleMatch(List<StudentMatchCandidate> candidates) {
    if (candidates.isEmpty) return false;
    if (candidates.first.isExact) return true;
    if (candidates.length == 1) return true;
    return candidates[0].score > candidates[1].score;
  }

  /// Finds the best student match, if confident enough.
  static StudentListItem? findStudent(
    List<StudentListItem> students,
    String spokenName,
  ) {
    final candidates = findStudentCandidates(students, spokenName, maxResults: 1);
    if (candidates.isEmpty) return null;
    if (isConfidentSingleMatch(candidates)) {
      return candidates.first.student;
    }
    return null;
  }

  /// Human-readable Arabic summary for confirmation UI.
  static String describeCommand(
    VoiceCommandResult parsed, {
    int? studentCount,
    String? resolvedStudentName,
    List<String>? absentStudentNames,
  }) {
    switch (parsed.type) {
      case VoiceCommandType.attendance:
        final count = studentCount ?? 0;
        return count > 0
            ? 'تحضير جميع الطلاب في الحلقة ($count طالب)'
            : 'تحضير جميع الطلاب في الحلقة';
      case VoiceCommandType.attendanceExcept:
        final count = studentCount ?? 0;
        final absentLabel = absentStudentNames != null &&
                absentStudentNames.isNotEmpty
            ? absentStudentNames.join('، ')
            : (parsed.excludedNamePhrases.isNotEmpty
                ? parsed.excludedNamePhrases.join('، ')
                : parsed.excludedNamesBlob ?? '—');
        final presentCount = count > 0 && absentStudentNames != null
            ? count - absentStudentNames.length
            : null;
        final presentPart = presentCount != null && presentCount > 0
            ? '\nتحضير $presentCount طالب'
            : '';
        return 'تحضير جميع الطلاب ما عدا:\n$absentLabel$presentPart';
      case VoiceCommandType.departure:
        final count = studentCount ?? 0;
        return count > 0
            ? 'تسجيل انصراف جميع الطلاب ($count طالب)'
            : 'تسجيل انصراف جميع الطلاب';
      case VoiceCommandType.assignPlan:
        final studentLabel =
            resolvedStudentName ?? parsed.studentName ?? 'طالب';
        final start = parsed.startSurahName ?? '—';
        final end = parsed.endSurahName ?? '—';
        final startAyah =
            '${parsed.startFromAyah ?? 1}–${parsed.startToAyah ?? 1}';
        final endAyah = '${parsed.endFromAyah ?? 1}–${parsed.endToAyah ?? 1}';
        return 'إنشاء خطة لـ $studentLabel\n'
            'من سورة $start (آية $startAyah)\n'
            'إلى سورة $end (آية $endAyah)';
      case VoiceCommandType.unrecognized:
        return 'أمر غير معروف';
    }
  }

  /// Maps a spoken Surah name to a valid database PlanSurahOption.
  static PlanSurahOption? matchSurah(List<PlanSurahOption> surahs, String spokenSurahName) {
    final normSpoken = normalizeArabic(spokenSurahName).trim();
    if (normSpoken.isEmpty) return null;

    // 1. Try exact normalized match
    for (final surah in surahs) {
      final normName = normalizeArabic(surah.name).trim();
      if (normName == normSpoken) {
        return surah;
      }
    }

    // Helper to strip "ال" prefix
    String stripAl(String s) {
      if (s.startsWith('ال')) {
        return s.substring(2);
      }
      return s;
    }

    final strippedSpoken = stripAl(normSpoken);

    // 2. Try match after removing "ال" prefix from either
    for (final surah in surahs) {
      final normName = normalizeArabic(surah.name).trim();
      final strippedName = stripAl(normName);
      if (strippedName == strippedSpoken) {
        return surah;
      }
    }

    // 3. Try containment match
    for (final surah in surahs) {
      final normName = normalizeArabic(surah.name).trim();
      if (normName.contains(normSpoken) || normSpoken.contains(normName)) {
        return surah;
      }
    }

    return null;
  }
}
