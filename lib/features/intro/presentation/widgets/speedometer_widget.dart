import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Speedometer-style progress: gradient arc + sweeping needle + numeric count-up.
class SpeedometerWidget extends StatelessWidget {
  const SpeedometerWidget({
    super.key,
    required this.progress,
    this.size = 220,
  });

  /// 0..1
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final value = (p * 100).round();
    final glow = (0.65 + 0.35 * math.sin(p * math.pi)).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: _SpeedometerPainter(progress: p),
              child: const SizedBox.expand(),
            ),
            Positioned(
              bottom: size * 0.18,
              child: Column(
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -0.6,
                          shadows: [
                            Shadow(color: AppColors.blue.withOpacity(0.12 * glow), blurRadius: 22),
                            Shadow(color: AppColors.purple.withOpacity(0.10 * glow), blurRadius: 26),
                          ],
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'READY',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  _SpeedometerPainter({required this.progress});

  final double progress;

  static const double _startAngle = math.pi * 0.86; // ~155°
  static const double _sweepAngle = math.pi * 1.28; // ~230°

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = size.shortestSide * 0.42;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.10);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), _startAngle, _sweepAngle, false, basePaint);

    final progRect = Rect.fromCircle(center: center, radius: r);
    final progPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweepAngle,
        colors: [
          AppColors.accentCyan,
          AppColors.purple,
          AppColors.blue,
          AppColors.accentCyan,
        ],
        stops: [0.0, 0.45, 0.8, 1.0],
      ).createShader(progRect);
    canvas.drawArc(progRect, _startAngle, _sweepAngle * progress, false, progPaint);

    // Tick marks (subtle).
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= 10; i++) {
      final a = _startAngle + _sweepAngle * (i / 10.0);
      final o = Offset(math.cos(a), math.sin(a));
      final p1 = center + o * (r + 12);
      final p2 = center + o * (r + 18);
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Needle.
    final needleA = _startAngle + _sweepAngle * progress;
    final needleDir = Offset(math.cos(needleA), math.sin(needleA));
    final needleLen = r + 14;
    final needlePaint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawLine(center, center + needleDir * needleLen, needlePaint);

    // Needle hub.
    final hub = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.92),
          AppColors.card.withOpacity(0.95),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 16));
    canvas.drawCircle(center, 10, hub);

    // Glow at completion.
    if (progress > 0.96) {
      final g = (progress - 0.96) / 0.04;
      final glow = Paint()
        ..color = AppColors.accentCyan.withOpacity(0.18 * g)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
      canvas.drawCircle(center, 18 + 20 * g, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) => oldDelegate.progress != progress;
}

