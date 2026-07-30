import 'package:flutter/material.dart';

/// Color palette for the premium splash screen.
abstract final class SplashColors {
  /// Deep navy background (login / register).
  static const Color background = Color(0xFF071B3A);

  /// Pure white for Arabic typography.
  static const Color whiteText = Color(0xFFFFFFFF);

  /// Gold accent — aligned with logo metallic gold.
  static const Color gold = Color(0xFFD4AF37);

  /// Floating particle color at 8% opacity.
  static Color get particle => Colors.white.withValues(alpha: 0.08);

  /// Soft radial light behind the mosque icon (5–8% opacity range).
  static Color lightRay(double opacity) =>
      Colors.white.withValues(alpha: opacity.clamp(0.05, 0.08));
}
