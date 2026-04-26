import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../shared/motion/app_haptics.dart';
import '../../../../shared/motion/scene_motion.dart';
import '../../../../shared/widgets/animated_background.dart';
import '../../../../shared/widgets/subtle_particle_field.dart';
import '../widgets/animated_logo_widget.dart';

/// Premium 2–3s launch splash. Does not own navigation — router redirects still control where to go.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _c;
  late final SceneMotionController _scene;
  bool _showSkip = false;
  Timer? _skipTimer;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _scene = SceneMotionController();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))..forward();

    _skipTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showSkip = true);
    });

    // After the logo sequence, yield to the intro (then intro yields to router chain).
    _navTimer = Timer(const Duration(milliseconds: 1950), () {
      if (!mounted) return;
      context.go('/intro');
    });
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    _navTimer?.cancel();
    _c.dispose();
    _scene.dispose();
    super.dispose();
  }

  void _skip() {
    AppHaptics.selection();
    _c.animateTo(1.0, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      context.go('/intro');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
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
            SubtleParticleField(motion: _scene, particleCount: 28),
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_c, _scene]),
                  builder: (context, _) {
                    final t = _c.value;
                    final sweep = Curves.easeInOutCubic.transform(((t - 0.12) / 0.7).clamp(0.0, 1.0));
                    return CustomPaint(
                      painter: _HeadlightSweepPainter(
                        t: t,
                        sweep: sweep,
                        parallax: _scene.backgroundParallax,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        AnimatedOpacity(
                          opacity: _showSkip ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
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
                        ),
                      ],
                    ),
                    const Spacer(),
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _c,
                        builder: (context, _) {
                          final t = _c.value;
                          return Column(
                            children: [
                              AnimatedLogoWidget(t: t, size: 112),
                              const SizedBox(height: 26),
                              _TitleBlock(t: t),
                              const SizedBox(height: 22),
                              _LoadingHint(
                                show: auth.isLoading && t > 0.78,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) {
                        final t = _c.value;
                        final fade = Curves.easeOut.transform(((t - 0.72) / 0.28).clamp(0.0, 1.0));
                        return Opacity(
                          opacity: fade,
                          child: Text(
                            'Smart Vehicle Intelligence',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Subtle end fade that blends into next route transition.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final t = _c.value;
                    final out = Curves.easeInCubic.transform(((t - 0.84) / 0.16).clamp(0.0, 1.0));
                    return ColoredBox(color: Colors.black.withOpacity(0.18 * out));
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

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final titleT = Curves.easeOutCubic.transform(((t - 0.28) / 0.38).clamp(0.0, 1.0));
    final subT = Curves.easeOutCubic.transform(((t - 0.44) / 0.40).clamp(0.0, 1.0));

    return Column(
      children: [
        Opacity(
          opacity: titleT,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - titleT)),
            child: Text(
              'Drivon',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    height: 1.0,
                    shadows: [
                      Shadow(color: AppColors.purple.withOpacity(0.25), blurRadius: 18),
                      Shadow(color: AppColors.blue.withOpacity(0.15), blurRadius: 26),
                    ],
                  ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: subT,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - subT)),
            child: Text(
              'Smart. Fast. Premium mobility.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingHint extends StatelessWidget {
  const _LoadingHint({required this.show});

  final bool show;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.85)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Starting…',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeadlightSweepPainter extends CustomPainter {
  _HeadlightSweepPainter({
    required this.t,
    required this.sweep,
    required this.parallax,
  });

  final double t;
  final double sweep;
  final Offset parallax;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final cx = size.width * (0.28 + 0.52 * sweep) + parallax.dx * 0.25;
    final cy = size.height * (0.42 + 0.05 * math.sin(t * math.pi * 2)) + parallax.dy * 0.18;

    final beamW = lerpDouble(size.width * 0.08, size.width * 0.42, sweep) ?? (size.width * 0.22);
    final beamH = size.height * 0.10;

    final beamRect = Rect.fromCenter(center: Offset(cx, cy), width: beamW, height: beamH);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.0),
          AppColors.accentCyan.withOpacity(0.10 * (1 - (sweep - 0.5).abs() * 1.6).clamp(0.0, 1.0)),
          Colors.white.withOpacity(0.06),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.35, 0.55, 1.0],
      ).createShader(beamRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);

    canvas.drawRRect(RRect.fromRectAndRadius(beamRect, const Radius.circular(999)), paint);

    // Very soft top wash (automotive premium “glass” feel).
    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.purple.withOpacity(0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6],
      ).createShader(rect);
    canvas.drawRect(rect, wash);
  }

  @override
  bool shouldRepaint(covariant _HeadlightSweepPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.sweep != sweep || oldDelegate.parallax != parallax;
  }
}

