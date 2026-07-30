import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:masged_parent_app/core/services/prayer_service.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../models/prayer_schedule_item.dart';
import '../models/prayer_sunnah_info.dart';
import '../models/prayer_times_data.dart';

class PrayerScheduleCard extends StatelessWidget {
  const PrayerScheduleCard({
    super.key,
    required this.item,
    required this.times,
  });

  final PrayerScheduleItem item;
  final PrayerTimesData times;

  @override
  Widget build(BuildContext context) {
    final prayer = item.prayer;
    final isWitrActive = item.isWitr && PrayerService.isWitrPeriod(times);
    final isNext = !item.isWitr &&
        prayer != null &&
        PrayerService.isNextPrayer(times, prayer);
    final isCurrent = !item.isWitr &&
        prayer != null &&
        times.currentPrayer() == prayer;
    final highlight = isNext || isWitrActive;

    final timeText = item.timeLabel ??
        intl.DateFormat('h:mm a', 'ar').format(item.time);
    final secondaryText = item.secondaryTime != null
        ? '${item.secondaryTimeLabel ?? ''} ${intl.DateFormat('h:mm a', 'ar').format(item.secondaryTime!)}'
            .trim()
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: highlight
            ? (isWitrActive ? const Color(0xFF5A4A8F) : AppColors.primary)
            : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: highlight
              ? (isWitrActive ? const Color(0xFF5A4A8F) : AppColors.primary)
              : isCurrent
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.border,
          width: isCurrent && !highlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: highlight ? 0.12 : 0.04),
            blurRadius: highlight ? 16.r : 10.r,
            offset: Offset(0, highlight ? 8.h : 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16.w,
              16.h,
              16.w,
              item.sunnah?.hasDetails == true ? 12.h : 16.h,
            ),
            child: Row(
              children: [
                _PrayerIconBadge(
                  icon: item.icon,
                  highlight: highlight,
                  isObligatory: item.isObligatory,
                  isWitr: item.isWitr,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.nameAr,
                            style: AppFonts.cairo(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: highlight
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (isWitrActive) ...[
                            SizedBox(width: 8.w),
                            _StatusChip(
                              label: 'وقت الوتر',
                              background: Colors.white.withValues(alpha: 0.2),
                              foreground: Colors.white,
                            ),
                          ] else if (isNext) ...[
                            SizedBox(width: 8.w),
                            _StatusChip(
                              label: 'القادمة',
                              background: Colors.white.withValues(alpha: 0.2),
                              foreground: Colors.white,
                            ),
                          ] else if (isCurrent) ...[
                            SizedBox(width: 8.w),
                            _StatusChip(
                              label: 'الحالية',
                              background: AppColors.primaryLight,
                              foreground: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                      if (!item.isObligatory && !item.isWitr) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'وقت الشروق — ليس صلاة',
                          style: AppFonts.cairo(
                            fontSize: 11.sp,
                            color: highlight
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ] else if (item.isWitr) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'بعد صلاة العشاء وسنتها',
                          style: AppFonts.cairo(
                            fontSize: 11.sp,
                            color: highlight
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: AppFonts.cairo(
                        fontSize: item.timeLabel != null ? 16.sp : 20.sp,
                        fontWeight: FontWeight.bold,
                        color: highlight ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (secondaryText != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        secondaryText,
                        style: AppFonts.cairo(
                          fontSize: 11.sp,
                          color: highlight
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (item.isObligatory)
                      Text(
                        'الأذان',
                        style: AppFonts.cairo(
                          fontSize: 10.sp,
                          color: highlight
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (item.sunnah?.hasDetails == true)
            _SunnahSection(
              sunnah: item.sunnah!,
              highlight: highlight,
              sectionTitle: item.detailsSectionTitle,
            ),
        ],
      ),
    );
  }
}

class _PrayerIconBadge extends StatelessWidget {
  const _PrayerIconBadge({
    required this.icon,
    required this.highlight,
    required this.isObligatory,
    required this.isWitr,
  });

  final IconData icon;
  final bool highlight;
  final bool isObligatory;
  final bool isWitr;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.r,
      height: 48.r,
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.2)
            : isWitr
                ? const Color(0xFFEDE9FE)
                : isObligatory
                    ? AppColors.primaryLight
                    : AppColors.goldLight,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Icon(
        icon,
        color: highlight
            ? Colors.white
            : isWitr
                ? const Color(0xFF6D28D9)
                : isObligatory
                    ? AppColors.primary
                    : AppColors.gold,
        size: 26.sp,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: AppFonts.cairo(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}

class _SunnahSection extends StatelessWidget {
  const _SunnahSection({
    required this.sunnah,
    required this.highlight,
    required this.sectionTitle,
  });

  final PrayerSunnahInfo sunnah;
  final bool highlight;
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.goldLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22.r),
          bottomRight: Radius.circular(22.r),
        ),
        border: Border(
          top: BorderSide(
            color: highlight
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.gold.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                sectionTitle == 'الوتر'
                    ? Icons.auto_awesome_rounded
                    : Icons.mosque_rounded,
                size: 16.sp,
                color: highlight ? AppColors.goldLight : AppColors.gold,
              ),
              SizedBox(width: 6.w),
              Text(
                sectionTitle,
                style: AppFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: highlight ? Colors.white : AppColors.gold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (sunnah.description != null) ...[
            Text(
              sunnah.description!,
              style: AppFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: highlight ? Colors.white : AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            if (sunnah.before != null || sunnah.after != null)
              SizedBox(height: 6.h),
          ],
          if (sunnah.before != null)
            _SunnahRow(
              label: 'قبل',
              text: sunnah.before!,
              highlight: highlight,
            ),
          if (sunnah.after != null) ...[
            if (sunnah.before != null || sunnah.description != null)
              SizedBox(height: 6.h),
            _SunnahRow(
              label: 'بعد',
              text: sunnah.after!,
              highlight: highlight,
            ),
          ],
          if (sunnah.note != null) ...[
            SizedBox(height: 8.h),
            Text(
              sunnah.note!,
              style: AppFonts.cairo(
                fontSize: 11.sp,
                color: highlight
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SunnahRow extends StatelessWidget {
  const _SunnahRow({
    required this.label,
    required this.text,
    required this.highlight,
  });

  final String label;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: highlight
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label,
            style: AppFonts.cairo(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: AppFonts.cairo(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.white : AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
