class MemorizingArchiveItem {
  const MemorizingArchiveItem({
    required this.id,
    required this.theType,
    required this.testFrom,
    required this.testTo,
    required this.isDone,
    this.notes,
    required this.createdAt,
  });

  final int id;
  final String theType;
  final String testFrom;
  final String testTo;
  final String isDone;
  final String? notes;
  final DateTime createdAt;

  factory MemorizingArchiveItem.fromJson(Map<String, dynamic> json) {
    return MemorizingArchiveItem(
      id: json['id'] as int? ?? 0,
      theType: json['theType'] as String? ?? '',
      testFrom: json['testFrom'] as String? ?? '',
      testTo: json['testTo'] as String? ?? '',
      isDone: json['isDone'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
