class AdhkarItem {
  const AdhkarItem({
    required this.id,
    required this.text,
    required this.count,
  });

  final int id;
  final String text;
  final int count;

  factory AdhkarItem.fromJson(Map<String, dynamic> json) {
    return AdhkarItem(
      id: json['id'] as int,
      text: json['text'] as String,
      count: json['count'] as int? ?? 1,
    );
  }
}
