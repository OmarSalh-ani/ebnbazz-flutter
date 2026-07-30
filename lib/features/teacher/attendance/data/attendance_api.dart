import 'package:masged_parent_app/teacher_core/network/api_client.dart';



class AttendanceApi {

  AttendanceApi(this._client);



  final TeacherApiClient _client;



  Map<String, dynamic> _coordinatesBody({

    required double latitude,

    required double longitude,

  }) =>

      {

        'latitude': latitude,

        'longitude': longitude,

      };



  Future<String> markAttendance(

    List<int> studentIds, {

    required double latitude,

    required double longitude,

    DateTime? attendanceDate,

  }) {

    final body = <String, dynamic>{

      'studentIds': studentIds,

      ..._coordinatesBody(latitude: latitude, longitude: longitude),

    };

    if (attendanceDate != null) {

      body['attendanceDate'] =

          '${attendanceDate.year}-${attendanceDate.month.toString().padLeft(2, '0')}-${attendanceDate.day.toString().padLeft(2, '0')}';

    }



    return _client.postCommand(

      '/api/studentsattendance/mark-attendance',

      body: body,

    );

  }



  Future<String> markDeparture(

    List<int> studentIds, {

    required double latitude,

    required double longitude,

  }) {

    return _client.postCommand(

      '/api/studentsattendance/mark-departure',

      body: {

        'studentIds': studentIds,

        ..._coordinatesBody(latitude: latitude, longitude: longitude),

      },

    );

  }



  Future<String> undoAttendance(

    int studentId, {

    required double latitude,

    required double longitude,

  }) {

    return _client.postCommand(

      '/api/studentsattendance/undo-attendance/$studentId',

      body: _coordinatesBody(latitude: latitude, longitude: longitude),

    );

  }



  Future<String> undoDeparture(

    int studentId, {

    required double latitude,

    required double longitude,

  }) {

    return _client.postCommand(

      '/api/studentsattendance/undo-departure/$studentId',

      body: _coordinatesBody(latitude: latitude, longitude: longitude),

    );

  }



  Future<ScanQrResult> scanQr({

    required String qrToken,

    required bool isDeparture,

    required double latitude,

    required double longitude,

  }) {

    return _client.post(

      '/api/studentsattendance/scan-qr',

      body: {

        'qrToken': qrToken,

        'isDeparture': isDeparture,

        ..._coordinatesBody(latitude: latitude, longitude: longitude),

      },

      parseData: ScanQrResult.fromJson,

    );

  }

}



class ScanQrResult {

  const ScanQrResult({

    required this.message,

    required this.studentId,

    required this.studentName,

  });



  final String message;

  final int studentId;

  final String studentName;



  factory ScanQrResult.fromJson(dynamic json) {

    final map = json as Map<String, dynamic>;

    return ScanQrResult(

      message: map['message'] as String? ?? '',

      studentId: map['studentId'] as int? ?? 0,

      studentName: map['studentName'] as String? ?? '',

    );

  }

}

