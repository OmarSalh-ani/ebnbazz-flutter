/// Matches server [VideoCallUidRules] in MasgedParentMobileAPI.
abstract final class VideoCallUid {
  static const int parentOffset = 1000000000;

  static int parentUid(int studentId) => parentOffset + studentId;

  /// Secondary Agora uid for teacher screen share in the same channel.
  static int teacherScreenUid(int teacherRtcUid) => teacherRtcUid + 1;

  static bool isTeacherRtcUid(int rtcUid) => rtcUid > 0 && rtcUid < parentOffset;

  /// Null if [rtcUid] is not in the parent-UID range (e.g. teacher id).
  static int? studentIdFromRtcUid(int rtcUid) {
    if (rtcUid < parentOffset) return null;
    return rtcUid - parentOffset;
  }
}
