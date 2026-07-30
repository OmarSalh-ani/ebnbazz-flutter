import 'package:flutter/material.dart';
import '../models/prayer_times_data.dart';
import 'prayer_sunnah_info.dart';

class PrayerScheduleItem {
  const PrayerScheduleItem({
    required this.nameAr,
    required this.time,
    required this.icon,
    this.prayer,
    this.sunnah,
    this.isObligatory = true,
    this.isWitr = false,
    this.timeLabel,
    this.secondaryTime,
    this.secondaryTimeLabel,
  });

  final String nameAr;
  final DateTime time;
  final IconData icon;
  final PrayerName? prayer;
  final PrayerSunnahInfo? sunnah;
  final bool isObligatory;
  final bool isWitr;

  /// Shown instead of [time] when set (e.g. "بعد العشاء").
  final String? timeLabel;
  final DateTime? secondaryTime;
  final String? secondaryTimeLabel;

  String get detailsSectionTitle => isWitr ? 'الوتر' : 'صلاة السنة';

  static const _sunnahByPrayer = <PrayerName, PrayerSunnahInfo>{
    PrayerName.fajr: PrayerSunnahInfo(
      before: 'ركعتان قبلها',
    ),
    PrayerName.dhuhr: PrayerSunnahInfo(
      before: '٤ ركعات قبلها',
      after: 'ركعتان بعدها',
      note: 'أو ركعتان قبلها وركعتان بعدها',
    ),
    PrayerName.maghrib: PrayerSunnahInfo(
      after: 'ركعتان بعدها',
    ),
    PrayerName.isha: PrayerSunnahInfo(
      after: 'ركعتان بعدها',
    ),
  };

  static const _witrInfo = PrayerSunnahInfo(
    description: 'ثلاث ركعات بعد سنة العشاء',
    note:
        'من ركعة إلى إحدى عشرة ركعة، والأفضل ثلاثٌ بقنوتٍ في الركعة الأخيرة. واجبة عند الجمهور.',
  );

  static List<PrayerScheduleItem> fromPrayerTimes(PrayerTimesData times) {
    return [
      PrayerScheduleItem(
        nameAr: 'الفجر',
        prayer: PrayerName.fajr,
        time: times.fajr,
        icon: Icons.nights_stay_rounded,
        sunnah: _sunnahByPrayer[PrayerName.fajr],
      ),
      PrayerScheduleItem(
        nameAr: 'الشروق',
        time: times.sunrise,
        icon: Icons.wb_twilight_rounded,
        isObligatory: false,
      ),
      PrayerScheduleItem(
        nameAr: 'الظهر',
        prayer: PrayerName.dhuhr,
        time: times.dhuhr,
        icon: Icons.wb_sunny_rounded,
        sunnah: _sunnahByPrayer[PrayerName.dhuhr],
      ),
      PrayerScheduleItem(
        nameAr: 'العصر',
        prayer: PrayerName.asr,
        time: times.asr,
        icon: Icons.cloud_rounded,
      ),
      PrayerScheduleItem(
        nameAr: 'المغرب',
        prayer: PrayerName.maghrib,
        time: times.maghrib,
        icon: Icons.nightlight_round,
        sunnah: _sunnahByPrayer[PrayerName.maghrib],
      ),
      PrayerScheduleItem(
        nameAr: 'العشاء',
        prayer: PrayerName.isha,
        time: times.isha,
        icon: Icons.dark_mode_rounded,
        sunnah: _sunnahByPrayer[PrayerName.isha],
      ),
      PrayerScheduleItem(
        nameAr: 'الوتر',
        time: times.isha,
        icon: Icons.auto_awesome_rounded,
        isObligatory: false,
        isWitr: true,
        timeLabel: 'بعد العشاء',
        secondaryTime: times.lastThird,
        secondaryTimeLabel: 'آخر وقت',
        sunnah: _witrInfo,
      ),
    ];
  }
}
