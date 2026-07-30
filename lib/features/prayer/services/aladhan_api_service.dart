import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prayer_times_data.dart';

class AlAdhanApiException implements Exception {
  AlAdhanApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AlAdhanApiService {
  static const _baseUrl = 'https://api.aladhan.com/v1/timings';

  Future<PrayerTimesData> fetchTimings(
    DateTime date,
    double lat,
    double lng,
  ) async {
    final dateStr = _formatDate(date);
    final uri = Uri.parse('$_baseUrl/$dateStr').replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw AlAdhanApiException('تعذر تحميل أوقات الصلاة');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'];
    if (code != 200) {
      throw AlAdhanApiException('تعذر تحميل أوقات الصلاة');
    }

    final data = body['data'] as Map<String, dynamic>?;
    final timings = data?['timings'] as Map<String, dynamic>?;
    if (timings == null) {
      throw AlAdhanApiException('تعذر تحميل أوقات الصلاة');
    }

    final tomorrow = date.add(const Duration(days: 1));
    final tomorrowTimings = await _fetchRawTimings(tomorrow, lat, lng);
    final tomorrowFajr = _parseTime(
      tomorrowTimings['Fajr'] as String? ?? '',
      tomorrow,
    );

    final fajr = _parseTime(timings['Fajr'] as String? ?? '', date);
    final lastThirdRaw = timings['Lastthird'] as String? ?? '';
    final lastThird = _parseTime(lastThirdRaw, date, beforeFajr: fajr);

    return PrayerTimesData(
      fajr: fajr,
      sunrise: _parseTime(timings['Sunrise'] as String? ?? '', date),
      dhuhr: _parseTime(timings['Dhuhr'] as String? ?? '', date),
      asr: _parseTime(timings['Asr'] as String? ?? '', date),
      maghrib: _parseTime(timings['Maghrib'] as String? ?? '', date),
      isha: _parseTime(timings['Isha'] as String? ?? '', date),
      lastThird: lastThird,
      fajrAfter: tomorrowFajr,
    );
  }

  Future<Map<String, dynamic>> _fetchRawTimings(
    DateTime date,
    double lat,
    double lng,
  ) async {
    final dateStr = _formatDate(date);
    final uri = Uri.parse('$_baseUrl/$dateStr').replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw AlAdhanApiException('تعذر تحميل أوقات الصلاة');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    return data?['timings'] as Map<String, dynamic>? ?? {};
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  DateTime _parseTime(
    String time,
    DateTime date, {
    DateTime? beforeFajr,
  }) {
    final parts = time.split(':');
    if (parts.length < 2) {
      throw AlAdhanApiException('تعذر تحميل أوقات الصلاة');
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    var result = DateTime(date.year, date.month, date.day, hour, minute);

    if (beforeFajr != null && result.isBefore(beforeFajr)) {
      result = result.add(const Duration(days: 1));
    }

    return result;
  }
}
