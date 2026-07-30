class AdhkarCategorySummary {
  const AdhkarCategorySummary({
    required this.id,
    required this.category,
    required this.itemsCount,
    required this.sortOrder,
  });

  final int id;
  final String category;
  final int itemsCount;
  final int sortOrder;

  factory AdhkarCategorySummary.fromJson(Map<String, dynamic> json) {
    return AdhkarCategorySummary(
      id: json['id'] as int? ?? 0,
      category: (json['category'] ?? json['name'] ?? '') as String,
      itemsCount: json['itemsCount'] as int? ?? 0,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
