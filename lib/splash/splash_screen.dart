import 'package:flutter/material.dart';

/// Full-bleed splash artwork asset.
const String kSplashScreenAsset = 'assets/images/splash_screen.png';

/// Exit fade duration — shared with [navigateWithFadeTransition].
const Duration kSplashExitFadeDuration = Duration(milliseconds: 500);

/// Brand splash screen showing the full-bleed center artwork.
///
/// Timeline:
/// - 0–600 ms: image fade in
/// - hold until 2800 ms
/// - 2800–3300 ms: exit fade, then [onComplete]
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  /// Called after the exit fade finishes — use for navigation.
  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _fadeInDuration = Duration(milliseconds: 600);
  static const _holdDuration = Duration(milliseconds: 2800);
  static const _exitFadeDuration = kSplashExitFadeDuration;

  late final AnimationController _fadeInController;
  late final AnimationController _exitFadeController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: _fadeInDuration,
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOutCubic,
    );
    _exitFadeController = AnimationController(
      vsync: this,
      duration: _exitFadeDuration,
    );
    _startSequence();
  }

  Future<void> _startSequence() async {
    _fadeInController.forward();

    await Future<void>.delayed(_holdDuration);
    if (!mounted) return;

    await _exitFadeController.forward();
    if (!mounted) return;

    widget.onComplete();
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _exitFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004B50),
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeIn, _exitFadeController]),
        builder: (context, _) {
          final opacity =
              (_fadeIn.value * (1.0 - _exitFadeController.value)).clamp(0.0, 1.0);

          return Opacity(
            opacity: opacity,
            child: Image.asset(
              kSplashScreenAsset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          );
        },
      ),
    );
  }
}

/// Navigates to [destination] with a 500 ms fade transition.
Future<void> navigateWithFadeTransition(
  BuildContext context,
  Widget destination,
) {
  return Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      transitionDuration: kSplashExitFadeDuration,
      reverseTransitionDuration: kSplashExitFadeDuration,
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    ),
  );
}
