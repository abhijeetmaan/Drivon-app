import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/drivon_logo.dart';

/// Cinematic launch mark: Drivon monogram “drives in” with subtle trail + motion blur.
class AnimatedLogoWidget extends StatelessWidget {
  const AnimatedLogoWidget({
    super.key,
    required this.t,
    this.size = 104,
  });

  /// Progress 0..1
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    final drive = Curves.easeOutCubic.transform((t / 0.62).clamp(0.0, 1.0));
    final settle = Curves.easeOutBack.transform(((t - 0.45) / 0.55).clamp(0.0, 1.0));
    final fade = Curves.easeOut.transform((t / 0.35).clamp(0.0, 1.0));

    final x = lerpDouble(-44, 0, drive) ?? 0;
    final bob = math.sin(settle * math.pi) * 1.6;

    return Opacity(
      opacity: fade,
      child: Transform.translate(
        offset: Offset(x, -bob),
        child: CustomPaint(
          painter: _TrailPainter(
            t: t,
            strength: drive,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Motion blur echoes (very subtle).
                for (final i in [3, 2, 1])
                  Transform.translate(
                    offset: Offset(-i * (5.0 * (1 - drive)), 0),
                    child: Opacity(
                      opacity: (0.06 + 0.05 * drive) * (i / 3.0),
                      child: DrivonLogo(size: size, glow: false),
                    ),
                  ),
                DrivonLogo(size: size, glow: true, pulse: (math.sin(settle * math.pi) * 0.5 + 0.5) * 0.7),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.t, required this.strength});

  final double t;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;

    // Trail lives behind the icon, drifting slightly like a headlight streak.
    final p = Curves.easeOutCubic.transform((t / 0.7).clamp(0.0, 1.0));
    final y = size.height * 0.5 + math.sin(t * math.pi * 2) * 2.2;

    final startX = size.width * 0.06;
    final endX = size.width * (0.52 + 0.12 * p);

    final rect = Rect.fromLTWH(startX, y - 10, endX - startX, 20);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.accentCyan.withOpacity(0.0),
          AppColors.accentCyan.withOpacity(0.14 * strength),
          Colors.white.withOpacity(0.08 * strength),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.34, 0.58, 1.0],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(999));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.strength != strength;
  }
}

