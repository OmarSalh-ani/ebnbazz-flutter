import 'package:flutter/material.dart';

class AttendanceRecordModel {
  final String day;
  final String date;
  final String status;
  final String statusKey;

  const AttendanceRecordModel({
    required this.day,
    required this.date,
    required this.status,
    required this.statusKey,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      day: json['day'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusKey: (json['statusKey'] as String? ?? 'absent').toLowerCase(),
    );
  }

  Color get statusColor {
    switch (statusKey) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'vacation':
        return Colors.blueGrey;
      default:
        return Colors.red;
    }
  }
}
