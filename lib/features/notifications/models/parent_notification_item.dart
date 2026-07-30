class ParentNotificationItem {
  final String kind;
  final int id;
  final String title;
  final String summary;
  final DateTime createdAt;
  final bool canJoin;
  final DateTime? endedAt;

  ParentNotificationItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.summary,
    required this.createdAt,
    this.canJoin = true,
    this.endedAt,
  });

  factory ParentNotificationItem.fromJson(Map<String, dynamic> json) {
    return ParentNotificationItem(
      kind: (json['kind'] ?? '').toString(),
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
      canJoin: json['canJoin'] as bool? ?? true,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'].toString())?.toLocal()
          : null,
    );
  }

  bool get isEndedMeeting => kind == 'meet' && !canJoin;
}
