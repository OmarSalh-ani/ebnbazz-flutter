import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Subtle 8-point star tile pattern for Islamic-themed backgrounds.
class IslamicPatternPainter extends CustomPainter {
  IslamicPatternPainter({
    this.color = AppColors.primary,
    this.opacity = 0.06,
    this.cellSize = 48,
  });

  final Color color;
  final double opacity;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
      for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
        _drawStar(
          canvas,
          Offset(x + cellSize / 2, y + cellSize / 2),
          cellSize * 0.35,
          paint,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 8;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (i * math.pi / points) - math.pi / 2;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.cellSize != cellSize;
  }
}

class IslamicPatternBackground extends StatelessWidget {
  const IslamicPatternBackground({
    super.key,
    required this.child,
    this.color,
    this.opacity,
  });

  final Widget child;
  final Color? color;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: IslamicPatternPainter(
        color: color ?? AppColors.primary,
        opacity: opacity ?? 0.06,
      ),
      child: child,
    );
  }
}
