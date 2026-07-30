import 'package:flutter/material.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';

class PulsingMicButton extends StatefulWidget {
  const PulsingMicButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  final bool isListening;
  final VoidCallback onTap;

  @override
  State<PulsingMicButton> createState() => _PulsingMicButtonState();
}

class _PulsingMicButtonState extends State<PulsingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.25);
        final opacity = 0.8 - (_controller.value * 0.5);

        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              Container(
                width: 110 * scale,
                height: 110 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: opacity),
                ),
              ),
            if (widget.isListening)
              Container(
                width: 90 * scale,
                height: 90 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: opacity + 0.1),
                ),
              ),
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: widget.isListening
                        ? [AppColors.primary, Colors.redAccent]
                        : [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isListening ? Icons.stop_rounded : Icons.mic_none,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
