class VideoCallStudentRef {
  VideoCallStudentRef({required this.id, required this.studentName});

  final int id;
  final String studentName;

  factory VideoCallStudentRef.fromJson(Map<String, dynamic> json) {
    return VideoCallStudentRef(
      id: json['id'] as int,
      studentName: (json['studentName'] ?? '').toString(),
    );
  }
}

class VideoCallCatalog {
  VideoCallCatalog({required this.teacherName, required this.students});

  final String teacherName;
  final List<VideoCallStudentRef> students;

  factory VideoCallCatalog.fromJson(Map<String, dynamic> json) {
    final list = json['students'] as List<dynamic>? ?? [];
    return VideoCallCatalog(
      teacherName: (json['teacherName'] ?? 'المعلم').toString(),
      students: list
          .map(
            (e) =>
                VideoCallStudentRef.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

class VideoCallListRow {
  VideoCallListRow({
    required this.id,
    required this.meetingName,
    required this.startDateTime,
    required this.channelName,
    required this.studentNames,
    required this.status,
    this.studentIdsRaw,
    this.endedAt,
    this.teacherNotes,
  });

  final int id;
  final String meetingName;
  final DateTime startDateTime;
  final String channelName;
  final String studentNames;
  final String? studentIdsRaw;
  final int status;
  final DateTime? endedAt;
  final String? teacherNotes;

  bool get isEnded => status == 1;
  bool get isActive => status == 0;

  factory VideoCallListRow.fromJson(Map<String, dynamic> json) {
    return VideoCallListRow(
      id: json['id'] as int,
      meetingName: (json['meetingName'] ?? '').toString(),
      startDateTime: DateTime.parse(json['startDateTime'].toString()).toLocal(),
      channelName: (json['channelName'] ?? json['meetingUrl'] ?? '').toString(),
      studentIdsRaw: json['studentIds']?.toString(),
      studentNames: (json['studentNames'] ?? '').toString(),
      status: (json['status'] as num?)?.toInt() ?? 0,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'].toString())?.toLocal()
          : null,
      teacherNotes: json['teacherNotes']?.toString(),
    );
  }
}

class VideoCallCreatedResult {
  VideoCallCreatedResult({
    required this.id,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.meetingName,
    required this.message,
  });

  final int id;
  final String channelName;
  final String token;
  final int uid;
  final String meetingName;
  final String message;

  factory VideoCallCreatedResult.fromJson(Map<String, dynamic> json) {
    return VideoCallCreatedResult(
      id: json['id'] as int,
      channelName: (json['channelName'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
      uid: (json['uid'] as num).toInt(),
      meetingName: (json['meetingName'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class VideoCallTokenResult {
  VideoCallTokenResult({
    required this.channelName,
    required this.token,
    required this.uid,
  });

  final String channelName;
  final String token;
  final int uid;

  factory VideoCallTokenResult.fromJson(Map<String, dynamic> json) {
    return VideoCallTokenResult(
      channelName: (json['channelName'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
      uid: (json['uid'] as num).toInt(),
    );
  }
}

class ParentVideoCallJoinResult {
  ParentVideoCallJoinResult({
    required this.meetingId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.meetingName,
    required this.studentId,
    this.teacherRtcUid,
  });

  final int meetingId;
  final String channelName;
  final String token;
  final int uid;
  final String meetingName;
  final int studentId;
  final int? teacherRtcUid;

  factory ParentVideoCallJoinResult.fromJson(Map<String, dynamic> json) {
    return ParentVideoCallJoinResult(
      meetingId: json['meetingId'] as int,
      channelName: (json['channelName'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
      uid: (json['uid'] as num).toInt(),
      meetingName: (json['meetingName'] ?? '').toString(),
      studentId: json['studentId'] as int,
      teacherRtcUid: (json['teacherRtcUid'] as num?)?.toInt(),
    );
  }
}
