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

class UnitTypeOption {
  const UnitTypeOption({required this.value, required this.label});

  final int value;
  final String label;

  factory UnitTypeOption.fromJson(Map<String, dynamic> json) {
    return UnitTypeOption(
      value: json['value'] as int,
      label: json['label'] as String? ?? '',
    );
  }
}

class PlanLevelFormData {
  const PlanLevelFormData({
    required this.unitTypes,
    required this.surahs,
    required this.jozzList,
    required this.defaultFromDate,
    required this.defaultToDate,
  });

  final List<UnitTypeOption> unitTypes;
  final List<IdNameOption> surahs;
  final List<IdNameOption> jozzList;
  final String defaultFromDate;
  final String defaultToDate;

  factory PlanLevelFormData.fromJson(Map<String, dynamic> json) {
    return PlanLevelFormData(
      unitTypes: (json['unitTypes'] as List<dynamic>? ?? [])
          .map((e) => UnitTypeOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      surahs: (json['surahs'] as List<dynamic>? ?? [])
          .map((e) => IdNameOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      jozzList: (json['jozzList'] as List<dynamic>? ?? [])
          .map((e) => IdNameOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultFromDate: json['defaultFromDate'] as String? ?? '',
      defaultToDate: json['defaultToDate'] as String? ?? '',
    );
  }
}

class PlanLevelItem {
  const PlanLevelItem({
    required this.id,
    required this.levelName,
    required this.unitType,
    required this.unitTypeDisplay,
    required this.quantity,
    required this.createdAt,
    required this.canEdit,
    this.createdByTeacherId,
  });

  final int id;
  final String levelName;
  final int unitType;
  final String unitTypeDisplay;
  final int quantity;
  final DateTime createdAt;
  final int? createdByTeacherId;
  final bool canEdit;

  bool get isGlobal => createdByTeacherId == null;

  factory PlanLevelItem.fromJson(Map<String, dynamic> json) {
    return PlanLevelItem(
      id: json['id'] as int,
      levelName: json['levelName'] as String? ?? '',
      unitType: json['unitType'] as int? ?? 0,
      unitTypeDisplay: json['unitTypeDisplay'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdByTeacherId: json['createdByTeacherId'] as int?,
      canEdit: json['canEdit'] as bool? ?? false,
    );
  }
}

class SavePlanLevelRequest {
  const SavePlanLevelRequest({
    required this.levelName,
    required this.unitType,
    required this.quantity,
  });

  final String levelName;
  final int unitType;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'levelName': levelName,
        'unitType': unitType,
        'quantity': quantity,
      };
}

class ReadyPlanItem {
  const ReadyPlanItem({
    required this.id,
    required this.planLevelId,
    required this.levelName,
    required this.fromSurahName,
    required this.toSurahName,
    required this.fromSurahId,
    required this.toSurahId,
    required this.fromDate,
    required this.toDate,
    required this.canEdit,
    this.fromAyah,
    this.toAyah,
    this.fromJozz,
    this.toJozz,
    this.createdByTeacherId,
  });

  final int id;
  final int planLevelId;
  final String levelName;
  final String fromSurahName;
  final String toSurahName;
  final int fromSurahId;
  final int toSurahId;
  final int? fromAyah;
  final int? toAyah;
  final int? fromJozz;
  final int? toJozz;
  final DateTime fromDate;
  final DateTime toDate;
  final int? createdByTeacherId;
  final bool canEdit;

  bool get isGlobal => createdByTeacherId == null;

  factory ReadyPlanItem.fromJson(Map<String, dynamic> json) {
    return ReadyPlanItem(
      id: json['id'] as int,
      planLevelId: json['planLevelId'] as int,
      levelName: json['levelName'] as String? ?? '',
      fromSurahName: json['fromSurahName'] as String? ?? '',
      toSurahName: json['toSurahName'] as String? ?? '',
      fromSurahId: json['fromSurahId'] as int? ?? 0,
      toSurahId: json['toSurahId'] as int? ?? 0,
      fromAyah: json['fromAyah'] as int?,
      toAyah: json['toAyah'] as int?,
      fromJozz: json['fromJozz'] as int?,
      toJozz: json['toJozz'] as int?,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      createdByTeacherId: json['createdByTeacherId'] as int?,
      canEdit: json['canEdit'] as bool? ?? false,
    );
  }
}

class SaveReadyPlanRequest {
  const SaveReadyPlanRequest({
    this.planLevelId,
    this.levelName,
    this.unitType,
    this.quantity,
    required this.fromSurahId,
    required this.toSurahId,
    this.fromAyah,
    this.toAyah,
    this.fromJozz,
    this.toJozz,
    required this.fromDate,
    required this.toDate,
  });

  final int? planLevelId;
  final String? levelName;
  final int? unitType;
  final int? quantity;
  final int fromSurahId;
  final int toSurahId;
  final int? fromAyah;
  final int? toAyah;
  final int? fromJozz;
  final int? toJozz;
  final String fromDate;
  final String toDate;

  Map<String, dynamic> toJson() => {
        if (planLevelId != null) 'planLevelId': planLevelId,
        if (levelName != null && levelName!.isNotEmpty) 'levelName': levelName,
        if (unitType != null) 'unitType': unitType,
        if (quantity != null) 'quantity': quantity,
        'fromSurahId': fromSurahId,
        'toSurahId': toSurahId,
        if (fromAyah != null) 'fromAyah': fromAyah,
        if (toAyah != null) 'toAyah': toAyah,
        if (fromJozz != null) 'fromJozz': fromJozz,
        if (toJozz != null) 'toJozz': toJozz,
        'fromDate': fromDate,
        'toDate': toDate,
      };
}

class PlanLevelPickItem {
  const PlanLevelPickItem({
    required this.id,
    required this.levelName,
    required this.unitType,
    required this.usesJozzInput,
  });

  final int id;
  final String levelName;
  final int unitType;
  final bool usesJozzInput;

  factory PlanLevelPickItem.fromJson(Map<String, dynamic> json) {
    return PlanLevelPickItem(
      id: json['id'] as int,
      levelName: json['levelName'] as String? ?? '',
      unitType: json['unitType'] as int? ?? 0,
      usesJozzInput: json['usesJozzInput'] as bool? ?? false,
    );
  }
}

class AssignPlanFormData {
  const AssignPlanFormData({
    required this.planLevels,
    required this.planTypes,
    required this.surahs,
    required this.jozzList,
    required this.students,
  });

  final List<PlanLevelPickItem> planLevels;
  final List<String> planTypes;
  final List<IdNameOption> surahs;
  final List<IdNameOption> jozzList;
  final List<IdNameOption> students;

  factory AssignPlanFormData.fromJson(Map<String, dynamic> json) {
    return AssignPlanFormData(
      planLevels: (json['planLevels'] as List<dynamic>? ?? [])
          .map((e) => PlanLevelPickItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      planTypes: (json['planTypes'] as List<dynamic>? ?? ['حفظ', 'مراجعة'])
          .map((e) => e as String)
          .toList(),
      surahs: (json['surahs'] as List<dynamic>? ?? [])
          .map((e) => IdNameOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      jozzList: (json['jozzList'] as List<dynamic>? ?? [])
          .map((e) => IdNameOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => IdNameOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AssignPlanRequest {
  const AssignPlanRequest({
    required this.studentIds,
    required this.planLevelId,
    required this.fromSurahId,
    required this.toSurahId,
    required this.fromDate,
    required this.toDate,
    required this.planType,
    this.fromJozz,
    this.toJozz,
    this.fromAyahNumber,
    this.toAyahNumber,
  });

  final List<int> studentIds;
  final int planLevelId;
  final int fromSurahId;
  final int toSurahId;
  final int? fromJozz;
  final int? toJozz;
  final String fromDate;
  final String toDate;
  final String planType;
  final int? fromAyahNumber;
  final int? toAyahNumber;

  Map<String, dynamic> toJson() => {
        'studentIds': studentIds,
        'planLevelId': planLevelId,
        'fromSurahId': fromSurahId,
        'toSurahId': toSurahId,
        if (fromJozz != null) 'fromJozz': fromJozz,
        if (toJozz != null) 'toJozz': toJozz,
        'fromDate': fromDate,
        'toDate': toDate,
        'planType': planType,
        if (fromAyahNumber != null) 'fromAyahNumber': fromAyahNumber,
        if (toAyahNumber != null) 'toAyahNumber': toAyahNumber,
      };
}
