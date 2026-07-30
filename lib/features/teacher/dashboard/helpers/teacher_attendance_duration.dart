class TeacherAttendanceDuration {
  TeacherAttendanceDuration._();

  static String format(Duration duration) {
    if (duration.isNegative) return '—';

    final totalMinutes = duration.inMinutes;
    if (totalMinutes <= 0) return 'أقل من دقيقة';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '$minutes دقيقة';
    }
    if (minutes == 0) {
      return '$hours ${_hourUnit(hours)}';
    }
    return '$hours ${_hourUnit(hours)} و $minutes ${_minuteUnit(minutes)}';
  }

  static String formatBetween({
    required DateTime? start,
    DateTime? end,
    bool showInProgress = false,
  }) {
    if (start == null) return '—';

    final resolvedEnd = end ??
        (showInProgress && _isToday(start) ? DateTime.now() : null);
    if (resolvedEnd == null) return '—';

    final label = format(resolvedEnd.difference(start));
    if (end == null && showInProgress && _isToday(start)) {
      return '$label (جاري)';
    }
    return label;
  }

  static bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  static String _hourUnit(int hours) => hours == 1 ? 'ساعة' : 'ساعات';

  static String _minuteUnit(int minutes) => minutes == 1 ? 'دقيقة' : 'دقائق';
}
