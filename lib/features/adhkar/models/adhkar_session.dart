class AdhkarSession {
  const AdhkarSession({
    required this.key,
    required this.categoryId,
  });

  final String key;
  final int categoryId;

  static String sessionKeyFor({required String? groupId, required int categoryId}) {
    if (groupId == 'morning') return 'morning';
    if (groupId == 'evening') return 'evening';
    return 'cat_$categoryId';
  }

  static AdhkarSession forGroup({
    required String? groupId,
    required int categoryId,
  }) {
    return AdhkarSession(
      key: sessionKeyFor(groupId: groupId, categoryId: categoryId),
      categoryId: categoryId,
    );
  }

  static AdhkarSession morning() {
    return const AdhkarSession(key: 'morning', categoryId: 1);
  }

  static AdhkarSession evening() {
    return const AdhkarSession(key: 'evening', categoryId: 1);
  }

  @override
  bool operator ==(Object other) {
    return other is AdhkarSession &&
        other.key == key &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(key, categoryId);
}
