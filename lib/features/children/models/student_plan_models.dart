class ParentPlanProgress {
  const ParentPlanProgress({
    required this.passed,
    required this.failed,
    required this.pending,
    required this.total,
    required this.progressPercent,
    required this.daysRemaining,
    required this.totalPlanDays,
  });

  final int passed;
  final int failed;
  final int pending;
  final int total;
  final int progressPercent;
  final int daysRemaining;
  final int totalPlanDays;

  factory ParentPlanProgress.fromJson(Map<String, dynamic> json) {
    return ParentPlanProgress(
      passed: json['passed'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      progressPercent: json['progressPercent'] as int? ?? 0,
      daysRemaining: json['daysRemaining'] as int? ?? 0,
      totalPlanDays: json['totalPlanDays'] as int? ?? 0,
    );
  }
}

class ParentPlanOverview {
  const ParentPlanOverview({
    this.planId,
    this.planName,
    this.planFromDate,
    this.planToDate,
    this.memorizationLevel,
    required this.progress,
  });

  final int? planId;
  final String? planName;
  final DateTime? planFromDate;
  final DateTime? planToDate;
  final String? memorizationLevel;
  final ParentPlanProgress progress;

  bool get hasPlan => planId != null;

  factory ParentPlanOverview.fromJson(Map<String, dynamic> json) {
    return ParentPlanOverview(
      planId: json['planId'] as int?,
      planName: json['planName'] as String?,
      planFromDate: json['planFromDate'] != null
          ? DateTime.parse(json['planFromDate'] as String)
          : null,
      planToDate: json['planToDate'] != null
          ? DateTime.parse(json['planToDate'] as String)
          : null,
      memorizationLevel: json['memorizationLevel'] as String?,
      progress: ParentPlanProgress.fromJson(
        json['progress'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class ParentPlanRow {
  const ParentPlanRow({
    required this.surahName,
    required this.fromAyahNumber,
    required this.toAyahNumber,
    required this.status,
    required this.statusDisplay,
    required this.planType,
  });

  final String surahName;
  final int fromAyahNumber;
  final int toAyahNumber;
  final String status;
  final String statusDisplay;
  final String planType;

  String get displayStatus =>
      statusDisplay.isNotEmpty ? statusDisplay : status;

  factory ParentPlanRow.fromJson(Map<String, dynamic> json) {
    return ParentPlanRow(
      surahName: json['surahName'] as String? ?? '',
      fromAyahNumber: json['fromAyahNumber'] as int? ?? 0,
      toAyahNumber: json['toAyahNumber'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      statusDisplay: json['statusDisplay'] as String? ?? '',
      planType: json['planType'] as String? ?? '',
    );
  }
}

class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final pageJson = _resolvePagedJson(json);
    final itemsJson = _readItemsJson(
      pageJson['items'] ?? pageJson['Items'],
    );
    return PagedResult(
      items: itemsJson
          .whereType<Map>()
          .map((e) => fromJsonT(Map<String, dynamic>.from(e)))
          .toList(),
      page: _readInt(pageJson['page'] ?? pageJson['Page']) ?? 1,
      pageSize: _readInt(pageJson['pageSize'] ?? pageJson['PageSize']) ?? 10,
      totalCount:
          _readInt(pageJson['totalCount'] ?? pageJson['TotalCount']) ?? 0,
      totalPages:
          _readInt(pageJson['totalPages'] ?? pageJson['TotalPages']) ?? 0,
    );
  }

  static Map<String, dynamic> _resolvePagedJson(Map<String, dynamic> json) {
    final nested = json['students'] ?? json['Students'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return json;
  }

  static List<dynamic> _readItemsJson(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;

    if (raw is Map) {
      final nestedItems = raw['items'] ?? raw['Items'];
      if (nestedItems != null) {
        return _readItemsJson(nestedItems);
      }
      if (raw.isNotEmpty) {
        return [raw];
      }
    }

    return const [];
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
