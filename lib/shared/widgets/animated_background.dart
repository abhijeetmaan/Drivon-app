import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../motion/scene_motion.dart';

/// Drifting blurred blobs + gradient wash. Reacts subtly to [motion] parallax (scroll / touch / nav).
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, this.motion});

  final SceneMotionController? motion;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 32))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[_c];
    if (widget.motion != null) listenables.add(widget.motion!);

    return RepaintBoundary(
      child: ListenableBuilder(
        listenable: Listenable.merge(listenables),
        builder: (context, _) {
          return CustomPaint(
            painter: _BlobPainter(
              t: _c.value,
              parallaxSlow: (widget.motion?.backgroundParallax ?? Offset.zero) * 0.35,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.t, required this.parallaxSlow});

  final double t;
  final Offset parallaxSlow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.background);

    final cx = size.width * 0.5 + parallaxSlow.dx;
    final cy = size.height * 0.34 + parallaxSlow.dy;

    final morph = math.sin(t * math.pi * 2) * 0.5 + 0.5;

    void blob(double phase, Color c, double r, double ox, double oy) {
      final wobble = lerpDouble(0.92, 1.06, morph)!;
      final px = cx + ox + math.sin((t + phase) * math.pi * 2) * size.width * 0.038 * wobble;
      final py = cy + oy + math.cos((t * 0.82 + phase) * math.pi * 2) * size.height * 0.028 * wobble;
      final g = RadialGradient(
        colors: [
          Color.lerp(c, AppColors.accentCyan, 0.08 + 0.1 * morph)!.withOpacity(0.10),
          c.withOpacity(0.035),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      );
      final paint = Paint()
        ..shader = g.createShader(Rect.fromCircle(center: Offset(px, py), radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(Offset(px, py), r, paint);
    }

    blob(0.0, AppColors.purple, size.shortestSide * 0.55, -size.width * 0.14, -size.height * 0.09);
    blob(0.33, AppColors.blue, size.shortestSide * 0.44, size.width * 0.19, size.height * 0.11);
    blob(0.66, AppColors.accentCyan, size.shortestSide * 0.30, -size.width * 0.06, size.height * 0.21);

    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.purple.withOpacity(0.045),
          Colors.transparent,
          AppColors.blue.withOpacity(0.038),
          AppColors.accentCyan.withOpacity(0.022),
        ],
        stops: const [0.0, 0.38, 0.72, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, wash);

    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.08,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.20),
        ],
        stops: const [0.62, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.parallaxSlow != parallaxSlow;
  }
}
