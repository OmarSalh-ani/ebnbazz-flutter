class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final pageJson = _resolvePagedJson(json);
    final itemsJson = _readItemsJson(
      pageJson['items'] ?? pageJson['Items'],
    );
    return PagedResult(
      items: itemsJson
          .whereType<Map>()
          .map((e) => fromJsonT(Map<String, dynamic>.from(e)))
          .toList(),
      page: _readInt(pageJson['page'] ?? pageJson['Page']) ?? 1,
      pageSize: _readInt(pageJson['pageSize'] ?? pageJson['PageSize']) ?? 10,
      totalCount:
          _readInt(pageJson['totalCount'] ?? pageJson['TotalCount']) ?? 0,
      totalPages:
          _readInt(pageJson['totalPages'] ?? pageJson['TotalPages']) ?? 0,
    );
  }

  static Map<String, dynamic> _resolvePagedJson(Map<String, dynamic> json) {
    final nested = json['students'] ?? json['Students'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return json;
  }

  static List<dynamic> _readItemsJson(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;

    if (raw is Map) {
      final nestedItems = raw['items'] ?? raw['Items'];
      if (nestedItems != null) {
        return _readItemsJson(nestedItems);
      }
      if (raw.isNotEmpty) {
        return [raw];
      }
    }

    return const [];
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
