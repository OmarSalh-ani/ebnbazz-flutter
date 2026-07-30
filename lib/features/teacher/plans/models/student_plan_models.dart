class PlanSurahOption {
  const PlanSurahOption({required this.id, required this.name});

  final int id;
  final String name;

  factory PlanSurahOption.fromJson(Map<String, dynamic> json) {
    return PlanSurahOption(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

class PlanFormData {
  const PlanFormData({required this.surahs});

  final List<PlanSurahOption> surahs;

  factory PlanFormData.fromJson(Map<String, dynamic> json) {
    final surahsJson = json['surahs'] as List<dynamic>? ?? [];
    return PlanFormData(
      surahs: surahsJson
          .map((e) => PlanSurahOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentPlanOverview {
  const StudentPlanOverview({
    required this.studentId,
    required this.studentName,
    required this.isNewPlanMode,
    required this.suggestedPlanId,
    required this.plans,
  });

  final int studentId;
  final String studentName;
  final bool isNewPlanMode;
  final int? suggestedPlanId;
  final List<StudentPlanSummary> plans;

  factory StudentPlanOverview.fromJson(Map<String, dynamic> json) {
    final plansJson = json['plans'] as List<dynamic>? ?? [];
    return StudentPlanOverview(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String? ?? '',
      isNewPlanMode: json['isNewPlanMode'] as bool? ?? false,
      suggestedPlanId: json['suggestedPlanId'] as int?,
      plans: plansJson
          .map((e) => StudentPlanSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentPlanSummary {
  const StudentPlanSummary({
    required this.id,
    required this.name,
    required this.planFromDate,
    required this.planToDate,
    required this.isCurrent,
  });

  final int id;
  final String name;
  final DateTime planFromDate;
  final DateTime planToDate;
  final bool isCurrent;

  factory StudentPlanSummary.fromJson(Map<String, dynamic> json) {
    return StudentPlanSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      planFromDate: DateTime.parse(json['planFromDate'] as String),
      planToDate: DateTime.parse(json['planToDate'] as String),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}

class PlanProgress {
  const PlanProgress({
    required this.passed,
    required this.failed,
    required this.pending,
    required this.total,
    required this.progressPercent,
    this.daysRemaining = 0,
    this.totalPlanDays = 0,
    this.daysElapsed = 0,
    this.circleDaysInRange = 0,
  });

  final int passed;
  final int failed;
  final int pending;
  final int total;
  final int progressPercent;
  final int daysRemaining;
  final int totalPlanDays;
  final int daysElapsed;
  final int circleDaysInRange;

  factory PlanProgress.fromJson(Map<String, dynamic> json) {
    return PlanProgress(
      passed: json['passed'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      progressPercent: json['progressPercent'] as int? ?? 0,
      daysRemaining: json['daysRemaining'] as int? ?? 0,
      totalPlanDays: json['totalPlanDays'] as int? ?? 0,
      daysElapsed: json['daysElapsed'] as int? ?? 0,
      circleDaysInRange: json['circleDaysInRange'] as int? ?? 0,
    );
  }
}

class PlanRow {
  const PlanRow({
    required this.key,
    required this.planType,
    required this.surahId,
    required this.surahName,
    required this.fromAyahNumber,
    required this.toAyahNumber,
    required this.status,
    required this.statusDisplay,
  });

  final String key;
  final String planType;
  final int surahId;
  final String surahName;
  final int fromAyahNumber;
  final int toAyahNumber;
  final String status;
  final String statusDisplay;

  factory PlanRow.fromJson(Map<String, dynamic> json) {
    return PlanRow(
      key: json['key'] as String? ?? '',
      planType: json['planType'] as String? ?? '',
      surahId: json['surahId'] as int? ?? 0,
      surahName: json['surahName'] as String? ?? '',
      fromAyahNumber: json['fromAyahNumber'] as int? ?? 0,
      toAyahNumber: json['toAyahNumber'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      statusDisplay: json['statusDisplay'] as String? ?? '',
    );
  }
}

extension PlanRowEdit on PlanRow {
  bool get canModify => key.isNotEmpty;
}

class StudentPlanDetail {
  const StudentPlanDetail({
    required this.studentId,
    required this.studentName,
    required this.planId,
    required this.planName,
    required this.planFromDate,
    required this.planToDate,
    required this.memorizationLevel,
    required this.progress,
    required this.currentMemorizing,
    required this.allRows,
    required this.plans,
  });

  final int studentId;
  final String studentName;
  final int planId;
  final String planName;
  final DateTime planFromDate;
  final DateTime planToDate;
  final String? memorizationLevel;
  final PlanProgress progress;
  final PlanRow? currentMemorizing;
  final List<PlanRow> allRows;
  final List<StudentPlanSummary> plans;

  factory StudentPlanDetail.fromJson(Map<String, dynamic> json) {
    final allRowsJson = json['allRows'] as List<dynamic>? ?? [];
    final plansJson = json['plans'] as List<dynamic>? ?? [];

    return StudentPlanDetail(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String? ?? '',
      planId: json['planId'] as int,
      planName: json['planName'] as String? ?? '',
      planFromDate: DateTime.parse(json['planFromDate'] as String),
      planToDate: DateTime.parse(json['planToDate'] as String),
      memorizationLevel: json['memorizationLevel'] as String?,
      progress: PlanProgress.fromJson(
        json['progress'] as Map<String, dynamic>? ?? {},
      ),
      currentMemorizing: json['currentMemorizing'] != null
          ? PlanRow.fromJson(json['currentMemorizing'] as Map<String, dynamic>)
          : null,
      allRows: allRowsJson
          .map((e) => PlanRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      plans: plansJson
          .map((e) => StudentPlanSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlanRowInput {
  const PlanRowInput({
    required this.surahId,
    required this.fromAyahNumber,
    required this.toAyahNumber,
    required this.planType,
  });

  final int surahId;
  final int fromAyahNumber;
  final int toAyahNumber;
  final String planType;

  Map<String, dynamic> toJson() => {
        'surahId': surahId,
        'fromAyahNumber': fromAyahNumber,
        'toAyahNumber': toAyahNumber,
        'planType': planType,
      };
}

class SurahRangeSelection {
  const SurahRangeSelection({
    required this.fromSurahId,
    required this.fromAyahNumber,
    required this.fromAyahEnd,
    required this.toSurahId,
    required this.toAyahStart,
    required this.toAyahNumber,
    required this.isReversed,
    required this.planType,
  });

  final int fromSurahId;
  final int fromAyahNumber;
  final int fromAyahEnd;
  final int toSurahId;
  final int toAyahStart;
  final int toAyahNumber;
  final bool isReversed;
  final String planType;

  Map<String, dynamic> toJson() => {
        'fromSurahId': fromSurahId,
        'fromAyahNumber': fromAyahNumber,
        'fromAyahEnd': fromAyahEnd,
        'toSurahId': toSurahId,
        'toAyahStart': toAyahStart,
        'toAyahNumber': toAyahNumber,
        'isReversed': isReversed,
        'planType': planType,
      };
}

class BulkAssignPlanRequest {
  const BulkAssignPlanRequest({
    required this.studentIds,
    required this.rows,
    this.addToExistingPlan = false,
    this.range,
    this.planName,
  });

  final List<int> studentIds;
  final List<PlanRowInput> rows;
  final bool addToExistingPlan;
  final SurahRangeSelection? range;
  final String? planName;

  Map<String, dynamic> toJson() => {
        'studentIds': studentIds,
        'addToExistingPlan': addToExistingPlan,
        'plan': {
          if (planName != null && planName!.isNotEmpty) 'planName': planName,
          'rows': rows.map((r) => r.toJson()).toList(),
          if (range != null) 'range': range!.toJson(),
        },
      };
}

class BulkAssignPlanStudentResult {
  const BulkAssignPlanStudentResult({
    required this.studentId,
    required this.studentName,
    required this.success,
    this.planId,
    this.message,
  });

  final int studentId;
  final String studentName;
  final bool success;
  final int? planId;
  final String? message;

  factory BulkAssignPlanStudentResult.fromJson(Map<String, dynamic> json) {
    return BulkAssignPlanStudentResult(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      planId: json['planId'] as int?,
      message: json['message'] as String?,
    );
  }
}

class BulkAssignPlanResponse {
  const BulkAssignPlanResponse({
    required this.successCount,
    required this.failedCount,
    required this.results,
  });

  final int successCount;
  final int failedCount;
  final List<BulkAssignPlanStudentResult> results;

  factory BulkAssignPlanResponse.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as List<dynamic>? ?? [];
    return BulkAssignPlanResponse(
      successCount: json['successCount'] as int? ?? 0,
      failedCount: json['failedCount'] as int? ?? 0,
      results: resultsJson
          .map(
            (e) => BulkAssignPlanStudentResult.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class ExpandedPlanRowPreview {
  const ExpandedPlanRowPreview({
    required this.surahId,
    required this.surahName,
    required this.fromAyahNumber,
    required this.toAyahNumber,
    required this.planType,
  });

  final int surahId;
  final String surahName;
  final int fromAyahNumber;
  final int toAyahNumber;
  final String planType;

  PlanRowInput toInput() => PlanRowInput(
        surahId: surahId,
        fromAyahNumber: fromAyahNumber,
        toAyahNumber: toAyahNumber,
        planType: planType,
      );

  factory ExpandedPlanRowPreview.fromJson(Map<String, dynamic> json) {
    return ExpandedPlanRowPreview(
      surahId: json['surahId'] as int,
      surahName: json['surahName'] as String? ?? '',
      fromAyahNumber: json['fromAyahNumber'] as int,
      toAyahNumber: json['toAyahNumber'] as int,
      planType: json['planType'] as String? ?? 'حفظ',
    );
  }
}
