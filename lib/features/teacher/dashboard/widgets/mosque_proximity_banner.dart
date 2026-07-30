import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:masged_parent_app/core/theme/app_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:masged_parent_app/core/theme/app_colors.dart';
import '../models/teacher_attendance_models.dart';

class MosqueProximityBanner extends StatefulWidget {
  const MosqueProximityBanner({
    super.key,
    required this.proximity,
  });

  final MosqueProximity proximity;

  @override
  State<MosqueProximityBanner> createState() => _MosqueProximityBannerState();
}

class _MosqueProximityBannerState extends State<MosqueProximityBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lineController;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proximity = widget.proximity;
    if (!proximity.hasMosqueLocation) {
      return _buildInfoCard(
        color: AppColors.warning.withOpacity(0.12),
        icon: Icons.location_off_outlined,
        iconColor: AppColors.warning,
        message: proximity.message,
      );
    }

    final isNear = proximity.isWithinRadius;
    final accent = isNear ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: AnimatedBuilder(
              animation: _lineController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ProximityLinePainter(
                    progress: _lineController.value,
                    lineColor: accent,
                    isNear: isNear,
                  ),
                  child: Row(
                    children: [
                      _buildEndpoint(
                        icon: Icons.person_pin_circle_rounded,
                        color: isNear ? accent : AppColors.primary,
                        label: 'أنت',
                      ),
                      const Spacer(),
                      _buildEndpoint(
                        icon: Icons.mosque_rounded,
                        color: accent,
                        label: 'المسجد',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            proximity.message,
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.85, end: 1, duration: 1200.ms),
          if (!isNear) ...[
            const SizedBox(height: 4),
            Text(
              'يجب أن تكون على بعد ${proximity.maxAllowedMeters.round()} متر أو أقل لتسجيل الحضور',
              textAlign: TextAlign.center,
              style: AppFonts.cairo(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEndpoint({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppFonts.cairo(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProximityLinePainter extends CustomPainter {
  _ProximityLinePainter({
    required this.progress,
    required this.lineColor,
    required this.isNear,
  });

  final double progress;
  final Color lineColor;
  final bool isNear;

  @override
  void paint(Canvas canvas, Size size) {
    const endpointWidth = 72.0;
    final start = Offset(endpointWidth, size.height / 2);
    final end = Offset(size.width - endpointWidth, size.height / 2);

    final paint = Paint()
      ..color = lineColor.withOpacity(0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, start, end, paint, dashLength: 8, gapLength: 6);

    final dotPaint = Paint()..color = lineColor;
    final travel = progress;
    final dotPos = Offset.lerp(start, end, travel)!;
    canvas.drawCircle(dotPos, isNear ? 4 : 5, dotPaint);

    if (!isNear) {
      final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;
      canvas.drawCircle(
        dotPos,
        8 + pulse * 4,
        Paint()
          ..color = lineColor.withOpacity(0.2 * (1 - pulse))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    final total = (end - start).distance;
    if (total <= 0) return;

    final direction = (end - start) / total;
    var distance = 0.0;
    var draw = true;

    while (distance < total) {
      final segment = draw ? dashLength : gapLength;
      final next = math.min(distance + segment, total);
      if (draw) {
        canvas.drawLine(
          start + direction * distance,
          start + direction * next,
          paint,
        );
      }
      distance = next;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _ProximityLinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.isNear != isNear;
}
