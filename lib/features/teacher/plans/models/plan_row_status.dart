/// Plan row statuses — must match [PlanRowStatus] in the API.
class PlanRowStatus {
  PlanRowStatus._();

  static const String pending = 'منتظر التسميع';
  static const String fail = 'لم يتم الحفظ';
  static const String retake = 'اعادة تسميع';
  static const String pass = 'تم الحفظ';

  static const List<String> selectable = [
    pending,
    fail,
    retake,
    pass,
  ];

  /// Mirrors backend [PlanRowStatus.Normalize] / [PlanRowStatus.IsPass].
  static String normalize(String? status) {
    final trimmed = status?.trim() ?? '';
    if (trimmed.isEmpty) return pending;

    switch (trimmed) {
      case 'تم':
      case 'قيد الانتظار في التثبيت':
        return pass;
      case 'لم يتم':
        return fail;
      case 'قيد الانتظار':
        return pending;
      default:
        return trimmed;
    }
  }

  static bool isPass(String? status) => normalize(status) == pass;
}
