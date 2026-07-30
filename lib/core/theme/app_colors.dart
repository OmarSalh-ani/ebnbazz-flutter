import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - brand theme color
  static const Color primary = Color(0xFF0D5C6D);
  static const Color primaryDark = Color(0xFF0B4E5D);
  static const Color primaryLight = Color(0xFFE6EFF0);

  // Gold/Accent (decorative elements)
  static const Color gold = Color(0xFFC9A96E);
  static const Color goldLight = Color(0xFFF5ECD8);

  // Backgrounds
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF7F8FA);

  // Borders
  static const Color border = Color(0xFFEEF0F3);
  static const Color inputBorder = Color(0xFFE2E6EA);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFADB5BD);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF4A8591), Color(0xFF0B4E5D)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4B483), Color(0xFFC9A96E)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D5C6D), Color(0xFF09404C)],
  );

  // Card gradients
  static const List<List<Color>> cardGradients = [
    [Color(0xFF0D5C6D), Color(0xFF0B4E5D)],
    [Color(0xFFC9A96E), Color(0xFFAD8850)],
    [Color(0xFF6C63FF), Color(0xFF5A52D5)],
    [Color(0xFF22C55E), Color(0xFF16A34A)],
  ];
}
