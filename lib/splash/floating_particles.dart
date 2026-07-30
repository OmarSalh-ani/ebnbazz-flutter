import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'splash_colors.dart';

/// Generates deterministic pseudo-random values for stable particle layout.
class _ParticleSeed {
  const _ParticleSeed({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
}

/// Slow upward-drifting particles with very low opacity.
class FloatingParticles extends StatelessWidget {
  const FloatingParticles({
    super.key,
    required this.progress,
    this.particleCount = 12,
  });

  /// Normalized animation progress (0 → 1, repeating).
  final double progress;

  final int particleCount;

  static const _seeds = <_ParticleSeed>[
    _ParticleSeed(x: 0.12, y: 0.78, radius: 1.6, speed: 0.18, phase: 0.05),
    _ParticleSeed(x: 0.28, y: 0.62, radius: 1.2, speed: 0.14, phase: 0.31),
    _ParticleSeed(x: 0.41, y: 0.88, radius: 1.4, speed: 0.16, phase: 0.52),
    _ParticleSeed(x: 0.55, y: 0.71, radius: 1.0, speed: 0.12, phase: 0.18),
    _ParticleSeed(x: 0.67, y: 0.54, radius: 1.8, speed: 0.20, phase: 0.74),
    _ParticleSeed(x: 0.78, y: 0.83, radius: 1.3, speed: 0.15, phase: 0.41),
    _ParticleSeed(x: 0.86, y: 0.66, radius: 1.1, speed: 0.13, phase: 0.63),
    _ParticleSeed(x: 0.19, y: 0.45, radius: 1.5, speed: 0.17, phase: 0.27),
    _ParticleSeed(x: 0.33, y: 0.38, radius: 1.2, speed: 0.11, phase: 0.89),
    _ParticleSeed(x: 0.48, y: 0.52, radius: 1.6, speed: 0.19, phase: 0.12),
    _ParticleSeed(x: 0.72, y: 0.41, radius: 1.4, speed: 0.14, phase: 0.56),
    _ParticleSeed(x: 0.91, y: 0.57, radius: 1.0, speed: 0.10, phase: 0.33),
    _ParticleSeed(x: 0.08, y: 0.59, radius: 1.3, speed: 0.16, phase: 0.71),
    _ParticleSeed(x: 0.62, y: 0.92, radius: 1.7, speed: 0.18, phase: 0.44),
    _ParticleSeed(x: 0.37, y: 0.74, radius: 1.1, speed: 0.12, phase: 0.08),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FloatingParticlesPainter(
          progress: progress,
          seeds: _seeds.take(particleCount).toList(growable: false),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _FloatingParticlesPainter extends CustomPainter {
  _FloatingParticlesPainter({
    required this.progress,
    required this.seeds,
  });

  final double progress;
  final List<_ParticleSeed> seeds;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = SplashColors.particle;

    for (final seed in seeds) {
      final drift = (progress + seed.phase) % 1.0;
      final y = size.height * (seed.y - drift * seed.speed);
      final x =
          size.width * seed.x + math.sin((drift + seed.phase) * math.pi * 2) * 6;

      canvas.drawCircle(Offset(x, y), seed.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
