import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:masged_parent_app/core/services/prayer_service.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../models/prayer_times_data.dart';

class PrayerTimesHero extends StatefulWidget {
  const PrayerTimesHero({
    super.key,
    required this.times,
  });

  final PrayerTimesData times;

  @override
  State<PrayerTimesHero> createState() => _PrayerTimesHeroState();
}

class _PrayerTimesHeroState extends State<PrayerTimesHero> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _prayerName(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
      case PrayerName.fajrAfter:
        return 'الفجر';
      case PrayerName.sunrise:
        return 'الشروق';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
      case PrayerName.ishaBefore:
        return 'العشاء';
    }
  }

  @override
  Widget build(BuildContext context) {
    final times = widget.times;
    final next = PrayerService.nextPrayer(times);
    final nextTime = PrayerService.nextPrayerDateTime(times);
    final isTomorrow = next == PrayerName.fajrAfter;
    final diff = nextTime.difference(DateTime.now());
    final isNow = !isTomorrow && diff.inSeconds <= 0;

    final totalSeconds = diff.inSeconds.clamp(0, 86400);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_filled_rounded,
                  color: Colors.white.withValues(alpha: 0.9), size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                isNow ? 'حان وقت الصلاة' : 'الصلاة القادمة',
                style: AppFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13.sp,
                ),
              ),
              const Spacer(),
              Text(
                intl.DateFormat('EEEE', 'ar').format(DateTime.now()),
                style: AppFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            _prayerName(next),
            style: AppFonts.cairo(
              color: Colors.white,
              fontSize: 34.sp,
              fontWeight: FontWeight.bold,
              height: 1.05,
            ),
          ),
          if (isTomorrow) ...[
            SizedBox(height: 4.h),
            Text(
              'غداً',
              style: AppFonts.cairo(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13.sp,
              ),
            ),
          ],
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isNow) ...[
                _CountdownPart(
                  value: hours.toString().padLeft(2, '0'),
                  unit: 'ساعة',
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
                  child: Text(
                    ':',
                    style: AppFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _CountdownPart(
                  value: minutes.toString().padLeft(2, '0'),
                  unit: 'دقيقة',
                ),
                SizedBox(width: 16.w),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأذان',
                    style: AppFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11.sp,
                    ),
                  ),
                  Text(
                    intl.DateFormat('h:mm a', 'ar').format(nextTime),
                    style: AppFonts.cairo(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownPart extends StatelessWidget {
  const _CountdownPart({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppFonts.cairo(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          unit,
          style: AppFonts.cairo(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}
