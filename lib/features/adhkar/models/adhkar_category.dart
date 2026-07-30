import 'adhkar_item.dart';

class AdhkarCategory {
  const AdhkarCategory({
    required this.id,
    required this.category,
    required this.items,
  });

  final int id;
  final String category;
  final List<AdhkarItem> items;

  factory AdhkarCategory.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['array'] ?? json['items']) as List<dynamic>? ?? [];
    return AdhkarCategory(
      id: json['id'] as int,
      category: (json['category'] ?? json['name'] ?? '') as String,
      items: rawItems
          .map((item) => AdhkarItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
