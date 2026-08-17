class MrkzMemorizingItem {
  const MrkzMemorizingItem({
    required this.id,
    required this.mtnName,
    required this.fromMtn,
    required this.toMtn,
    required this.createdDate,
    required this.planType,
  });

  static const planTypeMemorizing = 'حفظ';
  static const planTypeRevision = 'مراجعة';

  final int id;
  final String mtnName;
  final String fromMtn;
  final String toMtn;
  final DateTime createdDate;
  final String planType;

  factory MrkzMemorizingItem.fromMemorizingJson(Map<String, dynamic> json) {
    return MrkzMemorizingItem(
      id: json['id'] as int,
      mtnName: json['mtnName'] as String? ?? '',
      fromMtn: json['fromMtn'] as String? ?? '',
      toMtn: json['toMtn'] as String? ?? '',
      createdDate: DateTime.parse(json['createdDate'] as String),
      planType: planTypeMemorizing,
    );
  }

  factory MrkzMemorizingItem.fromRevisionJson(Map<String, dynamic> json) {
    return MrkzMemorizingItem(
      id: json['id'] as int,
      mtnName: json['mtnName'] as String? ?? '',
      fromMtn: json['fromMtn'] as String? ?? '',
      toMtn: json['toMtn'] as String? ?? '',
      createdDate: DateTime.parse(json['createdDate'] as String),
      planType: planTypeRevision,
    );
  }
}
