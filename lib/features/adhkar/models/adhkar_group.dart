import 'package:flutter/material.dart';

class AdhkarGroup {
  const AdhkarGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.categoryIds,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final List<int> categoryIds;
}
