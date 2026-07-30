import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/onboarding_colors.dart';

class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: OnboardingColors.backgroundDecoration,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _EmbossedCornerPattern(topRight: true),
          const _EmbossedCornerPattern(topRight: false),
          child,
        ],
      ),
    );
  }
}

class _EmbossedCornerPattern extends StatelessWidget {
  const _EmbossedCornerPattern({required this.topRight});

  final bool topRight;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: topRight ? 0 : null,
      left: topRight ? null : 0,
      child: SizedBox(
        width: 160,
        height: 160,
        child: CustomPaint(
          painter: _EmbossedCornerPainter(mirror: !topRight),
        ),
      ),
    );
  }
}

class _EmbossedCornerPainter extends CustomPainter {
  _EmbossedCornerPainter({required this.mirror});

  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final stroke = Paint()
      ..color = OnboardingColors.patternLight.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final origin = Offset(size.width * 0.92, size.height * 0.08);
    for (var ring = 0; ring < 6; ring++) {
      final radius = 18.0 + ring * 14.0;
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: radius),
        math.pi * 0.5,
        math.pi * 0.5,
        false,
        stroke,
      );
    }

    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        _drawStar(
          canvas,
          Offset(size.width * 0.52 + col * 16.0, size.height * 0.06 + row * 16.0),
          5.5,
          stroke,
        );
      }
    }

    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 8;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final angle = (math.pi / points) * i - math.pi / 2;
      final r = i.isEven ? radius : radius * 0.42;
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
  bool shouldRepaint(covariant _EmbossedCornerPainter oldDelegate) =>
      oldDelegate.mirror != mirror;
}
