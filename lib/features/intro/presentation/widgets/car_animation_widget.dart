import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Fake-3D car entry: headlights → body → reflection.
///
/// Designed to be GPU-friendly: mostly transforms + gradients, no heavy images.
class CarAnimationWidget extends StatelessWidget {
  const CarAnimationWidget({
    super.key,
    required this.t,
    this.width = 320,
  });

  /// Progress 0..1
  final double t;
  final double width;

  @override
  Widget build(BuildContext context) {
    final head = Curves.easeOutCubic.transform(((t - 0.04) / 0.20).clamp(0.0, 1.0));
    final body = Curves.easeOutCubic.transform(((t - 0.14) / 0.42).clamp(0.0, 1.0));
    final settle = Curves.easeOutBack.transform(((t - 0.22) / 0.56).clamp(0.0, 1.0));

    final z = lerpDouble(0.76, 1.0, body) ?? 1.0;
    final y = lerpDouble(42, 0, body) ?? 0;
    final tiltY = lerpDouble(0.52, 0.0, settle) ?? 0;
    final tiltX = lerpDouble(-0.10, 0.0, settle) ?? 0;

    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(tiltX)
      ..rotateY(tiltY);

    final glowPulse = 0.6 + 0.4 * math.sin((t * 0.9 + 0.08) * math.pi * 2);
    final highlight = (0.08 + 0.10 * glowPulse) * body;

    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: width * 0.52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ground reflection (subtle).
            Positioned(
              bottom: 0,
              child: Opacity(
                opacity: 0.22 * body,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(1.0, -1.0, 1.0),
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: Transform.scale(
                      scale: z * 0.98,
                      child: _CarSilhouette(
                        width: width,
                        fill: Colors.white.withOpacity(0.16),
                        gloss: Colors.transparent,
                        blurEchoes: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Under-car shadow.
            Positioned(
              bottom: 18,
              child: Opacity(
                opacity: 0.42 * body,
                child: Container(
                  width: width * 0.68,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 26,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Headlight glow (appears first).
            Positioned.fill(
              child: Opacity(
                opacity: head.clamp(0.0, 1.0),
                child: CustomPaint(
                  painter: _HeadlightGlowPainter(strength: head),
                ),
              ),
            ),

            // Car body + faux motion blur.
            Transform.translate(
              offset: Offset(0, y),
              child: Transform(
                alignment: Alignment.center,
                transform: m,
                child: Transform.scale(
                  scale: z,
                  child: _CarSilhouette(
                    width: width,
                    fill: Color.lerp(AppColors.card, Colors.white, 0.08)!.withOpacity(0.98),
                    gloss: Colors.white.withOpacity(highlight),
                    blurEchoes: (body < 0.98) ? 2 : 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarSilhouette extends StatelessWidget {
  const _CarSilhouette({
    required this.width,
    required this.fill,
    required this.gloss,
    required this.blurEchoes,
  });

  final double width;
  final Color fill;
  final Color gloss;
  final int blurEchoes;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.35;
    final body = SizedBox(
      width: width,
      height: h,
      child: CustomPaint(
        painter: _CarPainter(fill: fill, gloss: gloss),
      ),
    );

    if (blurEchoes <= 0) return body;

    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = blurEchoes; i >= 1; i--)
          Transform.translate(
            offset: Offset(-i * 8.0, 0),
            child: Opacity(opacity: 0.08 * (i / blurEchoes), child: body),
          ),
        body,
      ],
    );
  }
}

class _CarPainter extends CustomPainter {
  _CarPainter({required this.fill, required this.gloss});

  final Color fill;
  final Color gloss;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = h * 0.28;

    final path = Path();
    // Simplified “supercar” profile.
    path.moveTo(w * 0.10, h * 0.62);
    path.quadraticBezierTo(w * 0.18, h * 0.34, w * 0.32, h * 0.32);
    path.quadraticBezierTo(w * 0.42, h * 0.20, w * 0.55, h * 0.22);
    path.quadraticBezierTo(w * 0.68, h * 0.25, w * 0.76, h * 0.38);
    path.quadraticBezierTo(w * 0.88, h * 0.40, w * 0.92, h * 0.58);
    path.quadraticBezierTo(w * 0.94, h * 0.70, w * 0.88, h * 0.72);
    path.lineTo(w * 0.12, h * 0.72);
    path.quadraticBezierTo(w * 0.06, h * 0.70, w * 0.10, h * 0.62);
    path.close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(fill, Colors.white, 0.07)!,
          fill,
          Color.lerp(fill, Colors.black, 0.07)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.06, h * 0.20, w * 0.88, h * 0.58), Radius.circular(r)),
      Paint()..color = Colors.transparent,
    );
    canvas.drawPath(path, bodyPaint);

    // Cabin/glass
    final glass = Path()
      ..moveTo(w * 0.36, h * 0.35)
      ..quadraticBezierTo(w * 0.44, h * 0.23, w * 0.56, h * 0.25)
      ..quadraticBezierTo(w * 0.64, h * 0.27, w * 0.70, h * 0.40)
      ..lineTo(w * 0.36, h * 0.40)
      ..close();
    canvas.drawPath(
      glass,
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Gloss band.
    if (gloss.opacity > 0) {
      final glossRect = Rect.fromLTWH(w * 0.14, h * 0.28, w * 0.74, h * 0.22);
      final gPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            gloss,
            Colors.transparent,
          ],
          stops: const [0.28, 0.5, 0.72],
        ).createShader(glossRect);
      canvas.save();
      canvas.clipPath(path);
      canvas.drawRect(glossRect, gPaint);
      canvas.restore();
    }

    // Accent line (neon rim).
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.accentCyan.withOpacity(0.0),
          AppColors.accentCyan.withOpacity(0.18),
          AppColors.purple.withOpacity(0.14),
          AppColors.accentCyan.withOpacity(0.0),
        ],
        stops: const [0.0, 0.35, 0.6, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.gloss != gloss;
  }
}

class _HeadlightGlowPainter extends CustomPainter {
  _HeadlightGlowPainter({required this.strength});

  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void glow(Offset center, double radius, Color c) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            c.withOpacity(0.22 * strength),
            c.withOpacity(0.06 * strength),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawCircle(center, radius, paint);
    }

    glow(Offset(w * 0.32, h * 0.54), w * 0.12, AppColors.accentCyan);
    glow(Offset(w * 0.68, h * 0.54), w * 0.12, AppColors.accentCyan);
    glow(Offset(w * 0.50, h * 0.58), w * 0.20, AppColors.blue);
  }

  @override
  bool shouldRepaint(covariant _HeadlightGlowPainter oldDelegate) => oldDelegate.strength != strength;
}

