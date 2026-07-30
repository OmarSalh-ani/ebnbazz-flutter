import 'package:flutter/material.dart';

import 'splash_colors.dart';

/// Deep navy backdrop with a very subtle radial gradient and soft pulsing light.
class LightBackground extends StatelessWidget {
  const LightBackground({
    super.key,
    required this.lightScale,
    required this.lightOpacity,
  });

  /// Animated scale for the radial light (0.95 → 1.05).
  final double lightScale;

  /// Animated opacity for the radial light (0.05 → 0.08).
  final double lightOpacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            const Color(0xFF0C2447),
            SplashColors.background,
            SplashColors.background,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _AmbientLightPainter(
          scale: lightScale,
          opacity: lightOpacity,
        ),
      ),
    );
  }
}

/// Paints a soft radial glow intended to sit behind the mosque icon area.
class _AmbientLightPainter extends CustomPainter {
  _AmbientLightPainter({
    required this.scale,
    required this.opacity,
  });

  final double scale;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final baseRadius = size.shortestSide * 0.22;
    final radius = baseRadius * scale;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          SplashColors.lightRay(opacity),
          SplashColors.lightRay(opacity * 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientLightPainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.opacity != opacity;
  }
}
