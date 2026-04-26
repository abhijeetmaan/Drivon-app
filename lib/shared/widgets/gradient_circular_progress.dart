import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Circular progress with a purple→blue sweep; smooth stroke caps.
class GradientCircularProgress extends StatelessWidget {
  const GradientCircularProgress({
    super.key,
    required this.progress,
    this.size = 88,
    this.strokeWidth = 5,
    this.trackColor,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final track = trackColor ?? AppColors.textSecondary.withOpacity(0.18);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          trackColor: track,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;

    final sweep = math.max(0.02, math.pi * 2 * progress);

    final shaderRect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + math.pi * 2,
      tileMode: TileMode.clamp,
      colors: const [
        AppColors.purple,
        AppColors.blue,
        AppColors.purple,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(shaderRect);

    final fgPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}
