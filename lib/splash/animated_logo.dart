import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'splash_colors.dart';

/// Brand logo shown on splash, login, and register screens.
const String kSplashLogoAsset = 'assets/images/logo.png';

/// Animated brand logo with fade/scale entrance and a soft pulsing light.
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    super.key,
    required this.fade,
    required this.scale,
    required this.starTwinkle,
    required this.starEntrance,
    required this.lightScale,
    required this.lightOpacity,
  });

  /// Logo opacity (0 → 1), 700 ms easeOutCubic.
  final double fade;

  /// Logo scale (0.85 → 1.0), 900 ms easeOutBack.
  final double scale;

  /// Kept for splash_screen API compatibility (unused with current logo).
  final double starTwinkle;

  /// Kept for splash_screen API compatibility (unused with current logo).
  final double starEntrance;

  /// Radial light scale behind the logo (0.95 → 1.05).
  final double lightScale;

  /// Radial light opacity (0.05 → 0.08).
  final double lightOpacity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final logoWidth = math.min(maxWidth * 0.62, 280.0);

        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: logoWidth,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.scale(
                      scale: lightScale,
                      child: Container(
                        width: logoWidth * 0.72,
                        height: logoWidth * 0.72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              SplashColors.lightRay(lightOpacity),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Image.asset(
                        kSplashLogoAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
