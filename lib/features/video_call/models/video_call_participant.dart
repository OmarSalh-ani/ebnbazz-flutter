/// Student shown in the teacher mic-control strip during a video call.
class VideoCallParticipantInfo {
  const VideoCallParticipantInfo({
    required this.studentId,
    required this.fullName,
    this.imageUrl,
  });

  final int studentId;
  final String fullName;
  final String? imageUrl;

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'طالب';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  factory VideoCallParticipantInfo.fromStudent({
    required int studentId,
    required String name,
    String? imageUrl,
  }) {
    return VideoCallParticipantInfo(
      studentId: studentId,
      fullName: name,
      imageUrl: imageUrl,
    );
  }
}
