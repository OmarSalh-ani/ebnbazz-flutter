import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated bars shown when a participant is speaking.
class AudioSoundWaves extends StatefulWidget {
  const AudioSoundWaves({
    super.key,
    required this.active,
    this.color = const Color(0xFF4CAF50),
    this.size = 28,
  });

  final bool active;
  final Color color;
  final double size;

  @override
  State<AudioSoundWaves> createState() => _AudioSoundWavesState();
}

class _AudioSoundWavesState extends State<AudioSoundWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(AudioSoundWaves oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.active) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    const barCount = 4;
    final barWidth = widget.size * 0.14;
    final gap = widget.size * 0.08;
    final maxHeight = widget.size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: barCount * barWidth + (barCount - 1) * gap,
          height: maxHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (i) {
              final phase = (_controller.value + i * 0.18) % 1.0;
              final scale = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase * math.pi * 2));
              return Padding(
                padding: EdgeInsets.only(right: i < barCount - 1 ? gap : 0),
                child: Container(
                  width: barWidth,
                  height: maxHeight * scale,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(barWidth),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
