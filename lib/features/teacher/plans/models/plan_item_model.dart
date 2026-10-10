class PlanItemModel {
  final String id;
  final String surah;
  final int fromAyah;
  final int toAyah;
  final String type; // "حفظ", "مراجعة"
  final String status; // "تم", "لم يتم", "قيد الانتظار", "اعادة تسميع"
  final String date;

  const PlanItemModel({
    required this.id,
    required this.surah,
    required this.fromAyah,
    required this.toAyah,
    required this.type,
    required this.status,
    required this.date,
  });

  static List<PlanItemModel> demoPlans = [
    const PlanItemModel(
      id: '1',
      surah: 'البقرة',
      fromAyah: 1,
      toAyah: 5,
      type: 'حفظ',
      status: 'تم',
      date: '2026-05-17',
    ),
    const PlanItemModel(
      id: '2',
      surah: 'البقرة',
      fromAyah: 6,
      toAyah: 10,
      type: 'حفظ',
      status: 'لم يتم',
      date: '2026-05-17',
    ),
    const PlanItemModel(
      id: '3',
      surah: 'الفاتحة',
      fromAyah: 1,
      toAyah: 7,
      type: 'مراجعة',
      status: 'تم',
      date: '2026-05-16',
    ),
  ];
}
