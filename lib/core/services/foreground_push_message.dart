import 'package:flutter_riverpod/flutter_riverpod.dart';



class ForegroundPushMessage {

  const ForegroundPushMessage({

    required this.title,

    required this.body,

    this.isMeeting = false,

    this.meetingId,

    this.isChat = false,

    this.teacherId,

    this.studentId,

    this.teacherName,

    this.studentName,

    this.parentPhone,

  });



  final String title;

  final String body;

  final bool isMeeting;

  final int? meetingId;

  final bool isChat;

  final int? teacherId;

  final int? studentId;

  final String? teacherName;

  final String? studentName;

  final String? parentPhone;

}



final foregroundPushMessageProvider =

    StateProvider<ForegroundPushMessage?>((ref) => null);

