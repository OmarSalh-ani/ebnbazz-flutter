import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/prayer/models/prayer_times_data.dart';
import '../../features/prayer/services/aladhan_api_service.dart';

class PrayerLocationException implements Exception {
  const PrayerLocationException();

  @override
  String toString() =>
      'عذراً لا يمكن أحتساب أوقات الصلاة بشكل صحيح بدون تفعيل خدمة الموقع';
}

class PrayerService {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  final AlAdhanApiService _api = AlAdhanApiService();

  static PrayerName nextPrayer(PrayerTimesData times) {
    return times.nextPrayer();
  }

  static DateTime nextPrayerDateTime(PrayerTimesData times) {
    return times.nextPrayerDateTime();
  }

  static bool isNextPrayer(PrayerTimesData times, PrayerName prayer) {
    return times.isNextPrayer(prayer);
  }

  static bool isWitrPeriod(PrayerTimesData times) {
    return times.isWitrPeriod();
  }

  Future<PrayerTimesData> getPrayerTimes({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateOnly = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final dateKey =
        '${dateOnly.year}-${dateOnly.month}-${dateOnly.day}';

    final position = await _requireLocation();
    final lat = position.latitude;
    final lng = position.longitude;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'prayer_api_cache_$dateKey';
    final cachedLat = prefs.getDouble('${cacheKey}_lat');
    final cachedLng = prefs.getDouble('${cacheKey}_lng');
    final cachedJson = prefs.getString(cacheKey);

    if (cachedJson != null &&
        cachedLat == lat &&
        cachedLng == lng) {
      try {
        return _deserialize(cachedJson);
      } catch (_) {
        // Fall through to fresh fetch.
      }
    }

    _checkLocationChangeInBackground(cachedLat, cachedLng, dateKey);

    final times = await _api.fetchTimings(dateOnly, lat, lng);

    await prefs.setString(cacheKey, _serialize(times));
    await prefs.setDouble('${cacheKey}_lat', lat);
    await prefs.setDouble('${cacheKey}_lng', lng);

    return times;
  }

  Future<Position> _requireLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const PrayerLocationException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PrayerLocationException();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return position;
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw const PrayerLocationException();
    }
  }

  void _checkLocationChangeInBackground(
    double? cachedLat,
    double? cachedLng,
    String dateKey,
  ) {
    if (cachedLat == null || cachedLng == null) return;

    Future(() async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
        final distance = Geolocator.distanceBetween(
          cachedLat,
          cachedLng,
          position.latitude,
          position.longitude,
        );
        if (distance > 5000) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('prayer_api_cache_$dateKey');
          await prefs.remove('prayer_api_cache_${dateKey}_lat');
          await prefs.remove('prayer_api_cache_${dateKey}_lng');
        }
      } catch (_) {
        // Ignore background errors.
      }
    });
  }

  String _serialize(PrayerTimesData times) {
    return [
      times.fajr.toIso8601String(),
      times.sunrise.toIso8601String(),
      times.dhuhr.toIso8601String(),
      times.asr.toIso8601String(),
      times.maghrib.toIso8601String(),
      times.isha.toIso8601String(),
      times.lastThird.toIso8601String(),
      times.fajrAfter.toIso8601String(),
    ].join('|');
  }

  PrayerTimesData _deserialize(String raw) {
    final parts = raw.split('|');
    if (parts.length != 8) {
      throw FormatException('Invalid prayer cache');
    }
    return PrayerTimesData(
      fajr: DateTime.parse(parts[0]),
      sunrise: DateTime.parse(parts[1]),
      dhuhr: DateTime.parse(parts[2]),
      asr: DateTime.parse(parts[3]),
      maghrib: DateTime.parse(parts[4]),
      isha: DateTime.parse(parts[5]),
      lastThird: DateTime.parse(parts[6]),
      fajrAfter: DateTime.parse(parts[7]),
    );
  }
}
