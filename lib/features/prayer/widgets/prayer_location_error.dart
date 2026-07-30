import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:masged_parent_app/core/theme/app_colors.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';

class PrayerLocationError extends StatelessWidget {
  const PrayerLocationError({
    super.key,
    required this.onRetry,
    this.compact = false,
  });

  final VoidCallback onRetry;
  final bool compact;

  static Future<void> activateLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? 16.w : 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: compact ? 36.sp : 48.sp,
            color: AppColors.error,
          ),
          SizedBox(height: compact ? 12.h : 16.h),
          Text(
            'عذراً لا يمكن أحتساب أوقات الصلاة بشكل صحيح بدون تفعيل خدمة الموقع',
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: compact ? 14.sp : 16.sp,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          SizedBox(height: compact ? 12.h : 16.h),
          FilledButton(
            onPressed: () async {
              await activateLocation();
              onRetry();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'تفعيل الموقع',
              style: AppFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
