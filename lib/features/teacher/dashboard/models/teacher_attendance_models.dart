class TeacherAttendanceStatus {
  const TeacherAttendanceStatus({
    required this.status,
    required this.message,
    this.attendanceTime,
    this.departureTime,
    this.hasFingerprintRegistered = false,
  });

  final String status;
  final String message;
  final String? attendanceTime;
  final String? departureTime;
  final bool hasFingerprintRegistered;

  bool get isNotAttended => status == 'not_attended';
  bool get isAttended => status == 'attended';
  bool get isDeparted => status == 'departed';
  bool get isVacation => status == 'vacation';

  bool get canMarkAttendance => isNotAttended && !isVacation;
  bool get canMarkDeparture => isAttended && !isVacation;

  factory TeacherAttendanceStatus.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceStatus(
      status: json['status'] as String? ?? 'not_attended',
      message: json['message'] as String? ?? '',
      attendanceTime: json['attendanceTime'] as String?,
      departureTime: json['departureTime'] as String?,
      hasFingerprintRegistered:
          json['hasFingerprintRegistered'] as bool? ?? false,
    );
  }
}

class MosqueProximity {
  const MosqueProximity({
    required this.hasMosqueLocation,
    required this.distanceMeters,
    required this.distanceDisplay,
    required this.message,
    required this.isWithinRadius,
    required this.maxAllowedMeters,
  });

  final bool hasMosqueLocation;
  final double distanceMeters;
  final String distanceDisplay;
  final String message;
  final bool isWithinRadius;
  final double maxAllowedMeters;

  factory MosqueProximity.fromJson(Map<String, dynamic> json) {
    return MosqueProximity(
      hasMosqueLocation: json['hasMosqueLocation'] as bool? ?? false,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      distanceDisplay: json['distanceDisplay'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isWithinRadius: json['isWithinRadius'] as bool? ?? false,
      maxAllowedMeters: (json['maxAllowedMeters'] as num?)?.toDouble() ?? 200,
    );
  }
}

class LocationRequest {
  const LocationRequest({
    required this.latitude,
    required this.longitude,
    required this.fingerprintHash,
  });

  final double latitude;
  final double longitude;
  final String fingerprintHash;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'fingerprintHash': fingerprintHash,
      };
}

class TeacherAttendanceLogQuery {
  const TeacherAttendanceLogQuery({
    required this.fromDate,
    required this.toDate,
  });

  final DateTime fromDate;
  final DateTime toDate;

  String get fromDateParam =>
      '${fromDate.year.toString().padLeft(4, '0')}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}';

  String get toDateParam =>
      '${toDate.year.toString().padLeft(4, '0')}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherAttendanceLogQuery &&
          fromDateParam == other.fromDateParam &&
          toDateParam == other.toDateParam;

  @override
  int get hashCode => Object.hash(fromDateParam, toDateParam);
}

class TeacherAttendanceLogSummary {
  const TeacherAttendanceLogSummary({
    required this.totalRecords,
    required this.totalWithDeparture,
    required this.totalAttendanceOnly,
  });

  final int totalRecords;
  final int totalWithDeparture;
  final int totalAttendanceOnly;

  factory TeacherAttendanceLogSummary.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceLogSummary(
      totalRecords: json['totalRecords'] as int? ?? 0,
      totalWithDeparture: json['totalWithDeparture'] as int? ?? 0,
      totalAttendanceOnly: json['totalAttendanceOnly'] as int? ?? 0,
    );
  }
}

class TeacherAttendanceLogEntry {
  const TeacherAttendanceLogEntry({
    required this.id,
    required this.date,
    required this.day,
    required this.statusKey,
    required this.status,
    required this.attendanceTime,
    this.departureTime,
  });

  final int id;
  final String date;
  final String day;
  final String statusKey;
  final String status;
  final String attendanceTime;
  final String? departureTime;

  bool get isDeparted => statusKey == 'departed';

  DateTime? get attendanceDateTime => DateTime.tryParse(attendanceTime);
  DateTime? get departureDateTime =>
      departureTime == null ? null : DateTime.tryParse(departureTime!);

  factory TeacherAttendanceLogEntry.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceLogEntry(
      id: json['id'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      day: json['day'] as String? ?? '',
      statusKey: json['statusKey'] as String? ?? '',
      status: json['status'] as String? ?? '',
      attendanceTime: json['attendanceTime'] as String? ?? '',
      departureTime: json['departureTime'] as String?,
    );
  }
}

class TeacherAttendanceLogResponse {
  const TeacherAttendanceLogResponse({
    required this.fromDate,
    required this.toDate,
    required this.summary,
    required this.records,
  });

  final String fromDate;
  final String toDate;
  final TeacherAttendanceLogSummary summary;
  final List<TeacherAttendanceLogEntry> records;

  factory TeacherAttendanceLogResponse.fromJson(Map<String, dynamic> json) {
    final recordsJson = json['records'] as List<dynamic>? ?? [];
    return TeacherAttendanceLogResponse(
      fromDate: json['fromDate'] as String? ?? '',
      toDate: json['toDate'] as String? ?? '',
      summary: TeacherAttendanceLogSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      records: recordsJson
          .map((e) =>
              TeacherAttendanceLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
