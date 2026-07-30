enum PrayerName {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
  fajrAfter,
  ishaBefore,
}

class PrayerTimesData {
  const PrayerTimesData({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.lastThird,
    required this.fajrAfter,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime lastThird;
  final DateTime fajrAfter;

  DateTime timeForPrayer(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return fajr;
      case PrayerName.sunrise:
        return sunrise;
      case PrayerName.dhuhr:
        return dhuhr;
      case PrayerName.asr:
        return asr;
      case PrayerName.maghrib:
        return maghrib;
      case PrayerName.isha:
      case PrayerName.ishaBefore:
        return isha;
      case PrayerName.fajrAfter:
        return fajrAfter;
    }
  }

  PrayerName currentPrayer({DateTime? now}) {
    final current = now ?? DateTime.now();
    if (current.isBefore(fajr)) return PrayerName.ishaBefore;
    if (current.isBefore(sunrise)) return PrayerName.fajr;
    if (current.isBefore(dhuhr)) return PrayerName.sunrise;
    if (current.isBefore(asr)) return PrayerName.dhuhr;
    if (current.isBefore(maghrib)) return PrayerName.asr;
    if (current.isBefore(isha)) return PrayerName.maghrib;
    return PrayerName.isha;
  }

  PrayerName nextPrayer({DateTime? now}) {
    final current = now ?? DateTime.now();
    if (current.isBefore(fajr)) return PrayerName.fajr;
    if (current.isBefore(sunrise)) return PrayerName.sunrise;
    if (current.isBefore(dhuhr)) return PrayerName.dhuhr;
    if (current.isBefore(asr)) return PrayerName.asr;
    if (current.isBefore(maghrib)) return PrayerName.maghrib;
    if (current.isBefore(isha)) return PrayerName.isha;
    return PrayerName.fajrAfter;
  }

  DateTime nextPrayerDateTime({DateTime? now}) {
    return timeForPrayer(nextPrayer(now: now));
  }

  bool isNextPrayer(PrayerName prayer) {
    final next = nextPrayer();
    if (next == prayer) return true;
    if (next == PrayerName.fajrAfter && prayer == PrayerName.fajr) return true;
    return false;
  }

  bool isWitrPeriod({DateTime? now}) {
    final current = now ?? DateTime.now();
    return current.isAfter(isha) && current.isBefore(fajrAfter);
  }
}
