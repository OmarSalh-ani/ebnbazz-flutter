import '../../teacher/dashboard/models/dashboard_models.dart';
import '../models/video_call_models.dart';
import '../models/video_call_participant.dart';

List<int> parseStudentIdsFromCsv(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .toList();
}

Map<int, VideoCallParticipantInfo> participantsForStudents(
  Iterable<StudentListItem> students,
  Iterable<int> studentIds,
) {
  final byId = {for (final s in students) s.id: s};
  final map = <int, VideoCallParticipantInfo>{};
  for (final id in studentIds) {
    final student = byId[id];
    if (student != null) {
      map[id] = VideoCallParticipantInfo.fromStudent(
        studentId: student.id,
        name: student.name,
        imageUrl: student.imageUrl,
      );
    } else {
      map[id] = VideoCallParticipantInfo(
        studentId: id,
        fullName: 'طالب',
      );
    }
  }
  return map;
}

Map<int, VideoCallParticipantInfo> participantsFromMeetingRow(
  VideoCallListRow row,
  List<StudentListItem> students,
) {
  return participantsForStudents(
    students,
    parseStudentIdsFromCsv(row.studentIdsRaw),
  );
}
