class AvailableStudent {
  const AvailableStudent({
    required this.id,
    required this.studentName,
    required this.fatherPhone,
    required this.age,
  });

  final int id;
  final String studentName;
  final String fatherPhone;
  final int age;

  factory AvailableStudent.fromJson(Map<String, dynamic> json) {
    return AvailableStudent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      studentName: json['studentName'] as String? ?? '',
      fatherPhone: json['fatherPhone'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
    );
  }
}
