import '../../../core/utils/validators.dart';

class BirthdateHelper {
  BirthdateHelper._();

  static String sanitizeDatePartInput(String value, int maxLength, int maxValue) {
    final digits = Validators.digitsOnly(value);
    final clipped = digits.length > maxLength ? digits.substring(0, maxLength) : digits;
    if (clipped.isEmpty) return '';

    if (clipped.length == 1 && clipped == '0') return '0';

    if (clipped.length == 2 && clipped.startsWith('0')) {
      final parsed = int.tryParse(clipped);
      if (parsed != null && parsed >= 1 && parsed <= maxValue) return clipped;
      return clipped.substring(clipped.length - 1);
    }

    final parsed = int.tryParse(clipped);
    if (parsed == null) return '';
    if (parsed > maxValue) {
      return maxValue.toString().padLeft(2, '0');
    }
    return clipped;
  }

  static String padDatePartOnBlur(String value, int maxValue) {
    final digits = Validators.digitsOnly(value);
    if (digits.isEmpty) return '';

    final parsed = int.tryParse(digits);
    if (parsed == null || parsed < 1 || parsed > maxValue) return value;

    return parsed.toString().padLeft(2, '0');
  }

  static String? buildBirthdateIso(String day, String month, String year) {
    final d = int.tryParse(day);
    final m = int.tryParse(month);
    final y = int.tryParse(year);

    if (d == null || m == null || y == null || year.length != 4) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;

    final date = DateTime(y, m, d);
    if (date.year != y || date.month != m || date.day != d) return null;
    if (date.isAfter(DateTime.now())) return null;

    return '${y.toString().padLeft(4, '0')}-'
        '${m.toString().padLeft(2, '0')}-'
        '${d.toString().padLeft(2, '0')}';
  }
}
