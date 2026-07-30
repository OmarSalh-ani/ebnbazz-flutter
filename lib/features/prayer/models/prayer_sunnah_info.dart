/// Sunnah (rawatib), witr, or other prayer notes.
class PrayerSunnahInfo {
  const PrayerSunnahInfo({
    this.before,
    this.after,
    this.description,
    this.note,
  });

  final String? before;
  final String? after;
  final String? description;
  final String? note;

  bool get hasDetails =>
      before != null || after != null || description != null || note != null;
}
