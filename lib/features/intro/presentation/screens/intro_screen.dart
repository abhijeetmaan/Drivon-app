import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/motion/app_haptics.dart';
import '../../../../shared/motion/scene_motion.dart';
import '../../../../shared/widgets/animated_background.dart';
import '../../../../shared/widgets/subtle_particle_field.dart';
import '../services/intro_sound.dart';
import '../widgets/car_animation_widget.dart';
import '../widgets/speedometer_widget.dart';

/// INSANE-level (but clean) cinematic intro: fake-3D car + speedometer loading.
///
/// Stays within ~2.3s and then yields to the router redirect chain (home / onboarding / login).
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> with TickerProviderStateMixin {
  late final AnimationController _c;
  late final SceneMotionController _scene;

  bool _hapticCar = false;
  bool _hapticDone = false;
  bool _soundEngine = false;
  bool _soundWhoosh = false;

  Timer? _routeKick;

  @override
  void initState() {
    super.initState();
    _scene = SceneMotionController();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2350))
      ..addListener(_onTick)
      ..forward();

    // After the sequence, yield to the router (it will redirect to login/onboarding/home).
    _routeKick = Timer(const Duration(milliseconds: 2380), () {
      if (!mounted) return;
      AppHaptics.selection();
      context.go('/');
    });
  }

  @override
  void dispose() {
    _routeKick?.cancel();
    _c.removeListener(_onTick);
    _c.dispose();
    _scene.dispose();
    super.dispose();
  }

  void _onTick() {
    final t = _c.value;

    // Sync haptics + optional sounds.
    if (!_soundEngine && t > 0.06) {
      _soundEngine = true;
      IntroSound.engineStart();
    }
    if (!_soundWhoosh && t > 0.16) {
      _soundWhoosh = true;
      IntroSound.whoosh();
    }
    if (!_hapticCar && t > 0.18) {
      _hapticCar = true;
      AppHaptics.tap();
    }
    if (!_hapticDone && t > 0.92) {
      _hapticDone = true;
      AppHaptics.confirm();
    }
  }

  void _skip() {
    AppHaptics.selection();
    _c.animateTo(1, duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (e) => _scene.setTouchFromLocal(e.localPosition, size),
        onPointerUp: (_) => _scene.clearTouch(),
        onPointerCancel: (_) => _scene.clearTouch(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBackground(motion: _scene),
            SubtleParticleField(motion: _scene, particleCount: 26),
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_c, _scene]),
                  builder: (context, _) {
                    final t = _c.value;
                    return CustomPaint(
                      painter: _RoadStreaksPainter(t: t, parallax: _scene.backgroundParallax),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedBuilder(
                        animation: _c,
                        builder: (context, _) {
                          final t = _c.value;
                          final show = Curves.easeOut.transform(((t - 0.22) / 0.18).clamp(0.0, 1.0));
                          return Opacity(
                            opacity: show,
                            child: TextButton(
                              onPressed: _skip,
                              child: Text(
                                'Skip',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) {
                        final t = _c.value;
                        final carT = Curves.easeOutCubic.transform((t / 0.62).clamp(0.0, 1.0));
                        final meterT = Curves.easeOutCubic.transform(((t - 0.22) / 0.72).clamp(0.0, 1.0));
                        final shake = (t > 0.18 && t < 0.34)
                            ? math.sin((t - 0.18) * math.pi * 28) * (1 - ((t - 0.18) / 0.16)) * 0.9
                            : 0.0;

                        return Transform.translate(
                          offset: Offset(shake, 0),
                          child: Column(
                            children: [
                              CarAnimationWidget(t: carT, width: math.min(360, size.width - 32)),
                              const SizedBox(height: 26),
                              Transform.scale(
                                scale: 0.96 + 0.04 * meterT,
                                child: SpeedometerWidget(progress: meterT, size: math.min(230, size.width * 0.60)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) {
                        final t = _c.value;
                        final fade = Curves.easeOut.transform(((t - 0.46) / 0.22).clamp(0.0, 1.0));
                        return Opacity(
                          opacity: fade,
                          child: Text(
                            'Drivon',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // End glow + fade for a premium handoff.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final t = _c.value;
                    final done = Curves.easeInCubic.transform(((t - 0.90) / 0.10).clamp(0.0, 1.0));
                    return Stack(
                      children: [
                        Opacity(
                          opacity: 0.22 * done,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.15),
                                radius: 0.9,
                                colors: [
                                  AppColors.accentCyan.withOpacity(0.18),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                        ),
                        ColoredBox(color: Colors.black.withOpacity(0.18 * done)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadStreaksPainter extends CustomPainter {
  _RoadStreaksPainter({required this.t, required this.parallax});

  final double t;
  final Offset parallax;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;

    // “Road motion” streaks: diagonal, very subtle, moves slowly.
    final baseX = (t * 260 + parallax.dx * 0.4) % 120;
    final baseY = (t * 190 + parallax.dy * 0.35) % 120;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.035),
          AppColors.accentCyan.withOpacity(0.035),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.55, 1.0],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    for (var i = -2; i < 10; i++) {
      final x = baseX + i * 120.0;
      final y = baseY + i * 68.0;
      final p1 = Offset(x, y);
      final p2 = Offset(x + size.width * 0.32, y + size.height * 0.18);
      canvas.drawLine(p1, p2, paint);
    }

    // Soft top wash.
    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.purple.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.62],
      ).createShader(rect);
    canvas.drawRect(rect, wash);
  }

  @override
  bool shouldRepaint(covariant _RoadStreaksPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.parallax != parallax;
  }
}

