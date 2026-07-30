import 'video_call_participant.dart';
import 'video_call_uid.dart';

/// Active Agora channel context for [AgoraVideoCallScreen].
class VideoCallSession {
  const VideoCallSession({
    required this.channelName,
    required this.token,
    required this.uid,
    required this.meetingId,
    required this.isTeacher,
    required this.displayTitle,
    this.startDateTime,
    this.linkedStudentId,
    this.teacherRtcUid,
    this.participantsByStudentId = const {},
  });

  final String channelName;
  final String token;
  final int uid;
  final int meetingId;

  /// True if the teacher app opened this session.
  final bool isTeacher;

  final String displayTitle;

  /// When the meeting was scheduled / started (shown in the call UI).
  final DateTime? startDateTime;

  /// Parent session: backend-selected student whose mic toggles apply.
  final int? linkedStudentId;

  /// Parent session: teacher camera Agora uid (screen share = this + 1).
  final int? teacherRtcUid;

  /// Teacher session: invited students (id → name/photo for mic controls).
  final Map<int, VideoCallParticipantInfo> participantsByStudentId;

  factory VideoCallSession.teacher({
    required String channelName,
    required String token,
    required int uid,
    required int meetingId,
    required String displayTitle,
    DateTime? startDateTime,
    Map<int, VideoCallParticipantInfo> participantsByStudentId = const {},
  }) {
    return VideoCallSession(
      channelName: channelName,
      token: token,
      uid: uid,
      meetingId: meetingId,
      isTeacher: true,
      displayTitle: displayTitle,
      startDateTime: startDateTime,
      linkedStudentId: null,
      participantsByStudentId: participantsByStudentId,
    );
  }

  factory VideoCallSession.parent({
    required String channelName,
    required String token,
    required int studentId,
    required int meetingId,
    required String displayTitle,
    DateTime? startDateTime,
    int? teacherRtcUid,
  }) {
    return VideoCallSession(
      channelName: channelName,
      token: token,
      uid: VideoCallUid.parentUid(studentId),
      meetingId: meetingId,
      isTeacher: false,
      displayTitle: displayTitle,
      startDateTime: startDateTime,
      linkedStudentId: studentId,
      teacherRtcUid: teacherRtcUid,
    );
  }
}
