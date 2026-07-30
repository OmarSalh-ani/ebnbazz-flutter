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
}
