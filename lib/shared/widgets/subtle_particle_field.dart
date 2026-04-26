import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../motion/scene_motion.dart';

/// Lightweight drifting particles; parallax from [motion]. Keeps count low for mid-range devices.
class SubtleParticleField extends StatefulWidget {
  const SubtleParticleField({
    super.key,
    this.motion,
    this.particleCount = 42,
  });

  final SceneMotionController? motion;
  final int particleCount;

  @override
  State<SubtleParticleField> createState() => _SubtleParticleFieldState();
}

class _SubtleParticleFieldState extends State<SubtleParticleField> with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 48))..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[_drift];
    if (widget.motion != null) listenables.add(widget.motion!);

    return IgnorePointer(
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: Listenable.merge(listenables),
          builder: (context, _) {
            return CustomPaint(
              painter: _ParticlePainter(
                t: _drift.value,
                seed: _rng,
                count: widget.particleCount,
                parallax: widget.motion?.particleParallax ?? Offset.zero,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.t,
    required math.Random seed,
    required this.count,
    required this.parallax,
  })  : _phases = List.generate(count, (i) => seed.nextDouble()),
        _sizes = List.generate(count, (i) => 1.2 + seed.nextDouble() * 2.4),
        _speeds = List.generate(count, (i) => 0.15 + seed.nextDouble() * 0.35);

  final double t;
  final int count;
  final List<double> _phases;
  final List<double> _sizes;
  final List<double> _speeds;
  final Offset parallax;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    for (var i = 0; i < count; i++) {
      final p = _phases[i];
      final spd = _speeds[i];
      final baseX = (p * size.width + math.sin((t * spd + p) * math.pi * 2) * size.width * 0.06) % (size.width + 40) - 20;
      final baseY = (p * 1.17 * size.height + math.cos((t * spd * 0.9 + p * 1.3) * math.pi * 2) * size.height * 0.05) % (size.height + 40) - 20;

      final ox = baseX + parallax.dx * (0.08 + p * 0.04);
      final oy = baseY + parallax.dy * (0.08 + p * 0.04);

      final opacity = 0.1 + (p % 0.17) * 0.75;
      final r = _sizes[i];
      final paint = Paint()
        ..color = Color.lerp(AppColors.accentCyan, AppColors.purple, p)!.withOpacity(opacity.clamp(0.08, 0.26))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(ox, oy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.parallax != parallax ||
        oldDelegate.count != count;
  }
}
