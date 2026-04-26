import 'dart:math' as math;

import 'package:flutter/material.dart';

class Waveform extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double height;

  const Waveform({
    super.key,
    required this.animation,
    required this.color,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => CustomPaint(
          painter: _WaveformPainter(t: animation.value, color: color),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double t;
  final Color color;
  _WaveformPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.85);

    final mid = size.height / 2;
    final w = size.width;

    final path = Path();
    for (double x = 0; x <= w; x += 6) {
      final phase = (x / w) * math.pi * 2;
      final amp = (0.28 + 0.20 * math.sin((t * 2 * math.pi) + phase * 0.6));
      final y = mid + math.sin(phase * 2 + t * 8) * (mid * amp);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}

