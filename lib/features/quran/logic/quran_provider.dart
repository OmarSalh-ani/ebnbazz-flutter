import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quranDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final surahsJson = await rootBundle.loadString('assets/json/surahs.json');
  final quartersJson = await rootBundle.loadString('assets/json/quarters.json');
  return {
    'surahs': json.decode(surahsJson),
    'quarters': json.decode(quartersJson),
  };
});
