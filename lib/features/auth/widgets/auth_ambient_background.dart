import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Dark ambient layer: very subtle drifting blobs (≈0.2–0.26) + blur.
class AuthAmbientBackground extends StatefulWidget {
  const AuthAmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuthAmbientBackground> createState() => _AuthAmbientBackgroundState();
}

class _AuthAmbientBackgroundState extends State<AuthAmbientBackground>
    with TickerProviderStateMixin {
  late final AnimationController _a1;
  late final AnimationController _a2;
  late final AnimationController _a3;

  static const _base = Color(0xFF0B0F1A);
  static final _pink = const Color(0xFFEC4899).withOpacity(0.22);
  static final _purple = AppColors.purple.withOpacity(0.24);
  static final _blue = AppColors.blue.withOpacity(0.21);

  @override
  void initState() {
    super.initState();
    _a1 = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat(reverse: true);
    _a2 = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(reverse: true);
    _a3 = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _a1.dispose();
    _a2.dispose();
    _a3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _base),
        AnimatedBuilder(
          animation: Listenable.merge([_a1, _a2, _a3]),
          builder: (context, _) {
            final t1 = _a1.value;
            final t2 = _a2.value;
            final t3 = _a3.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: -60 + 65 * math.sin(t1 * math.pi * 2),
                  top: -40 + 45 * math.cos(t1 * math.pi * 2 * 0.7),
                  child: _Blob(
                    size: 280,
                    gradient: RadialGradient(
                      colors: [_purple, _purple.withOpacity(0)],
                    ),
                  ),
                ),
                Positioned(
                  right: -80 + 55 * math.cos(t2 * math.pi * 2),
                  top: 120 + 38 * math.sin(t2 * math.pi * 2),
                  child: _Blob(
                    size: 320,
                    gradient: RadialGradient(
                      colors: [_blue, _blue.withOpacity(0)],
                    ),
                  ),
                ),
                Positioned(
                  left: 40 + 42 * math.sin(t3 * math.pi * 2),
                  bottom: 80 + 50 * math.cos(t3 * math.pi * 2 * 0.8),
                  child: _Blob(
                    size: 240,
                    gradient: RadialGradient(
                      colors: [_pink, _pink.withOpacity(0)],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.gradient});

  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
        ),
      ),
    );
  }
}
