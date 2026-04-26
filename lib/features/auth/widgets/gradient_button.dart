import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';

/// Gradient CTA: tap scale, loading, success check + glow pulse, optional demo pulse.
class GradientAuthButton extends StatefulWidget {
  const GradientAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.showSuccess = false,
    this.demoPulse = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showSuccess;
  final bool demoPulse;

  @override
  State<GradientAuthButton> createState() => _GradientAuthButtonState();
}

class _GradientAuthButtonState extends State<GradientAuthButton> with TickerProviderStateMixin {
  double _pressScale = 1;
  late AnimationController _successPop;
  late AnimationController _glowPulse;
  late AnimationController _demoPulse;

  @override
  void initState() {
    super.initState();
    _successPop = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _glowPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _demoPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void didUpdateWidget(covariant GradientAuthButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showSuccess && widget.showSuccess) {
      HapticFeedback.mediumImpact();
      _successPop.forward(from: 0);
      _glowPulse.forward(from: 0).whenComplete(() {
        if (mounted) _glowPulse.reverse();
      });
    }
    if (!oldWidget.demoPulse && widget.demoPulse) {
      _demoPulse.repeat(reverse: true);
    }
    if (oldWidget.demoPulse && !widget.demoPulse) {
      _demoPulse.stop();
      _demoPulse.reset();
    }
  }

  @override
  void dispose() {
    _successPop.dispose();
    _glowPulse.dispose();
    _demoPulse.dispose();
    super.dispose();
  }

  void _tapDown(TapDownDetails _) {
    if (widget.isLoading || widget.showSuccess || widget.onPressed == null) return;
    setState(() => _pressScale = 0.97);
    HapticFeedback.lightImpact();
  }

  void _tapUp(TapUpDetails _) => setState(() => _pressScale = 1);
  void _tapCancel() => setState(() => _pressScale = 1);

  @override
  Widget build(BuildContext context) {
    final idleTap = widget.onPressed != null && !widget.isLoading && !widget.showSuccess;
    final showLoader = widget.isLoading && !widget.showSuccess;
    final showCheck = widget.showSuccess;

    return AnimatedBuilder(
      animation: Listenable.merge([_glowPulse, _demoPulse, _successPop]),
      builder: (context, _) {
        final pulseT = _glowPulse.value;
        final demoT = _demoPulse.value;
        final extraGlow = 0.26 * pulseT +
            (widget.demoPulse ? 0.2 * (math.sin(demoT * math.pi * 2) * 0.5 + 0.5) : 0);
        final blur = 22 + 18 * pulseT + (widget.demoPulse ? 10 * demoT : 0);

        return AnimatedScale(
          scale: _pressScale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            elevation: idleTap || showLoader ? 8 : 0,
            shadowColor: AppColors.purple.withOpacity(0.38 + extraGlow * 0.2),
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: idleTap ? widget.onPressed : null,
              onTapDown: idleTap ? _tapDown : null,
              onTapUp: idleTap ? _tapUp : null,
              onTapCancel: idleTap ? _tapCancel : null,
              borderRadius: BorderRadius.circular(30),
              splashColor: Colors.white.withOpacity(0.18),
              highlightColor: Colors.white.withOpacity(0.08),
              child: Ink(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: showCheck
                        ? [
                            AppColors.purple.withOpacity(0.94),
                            AppColors.blue.withOpacity(0.9),
                          ]
                        : [
                            AppColors.purple,
                            AppColors.purple.withOpacity(0.88),
                            AppColors.blue,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withOpacity(0.42 + extraGlow),
                      blurRadius: blur,
                      offset: const Offset(0, 10),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: AppColors.blue.withOpacity(0.15 + extraGlow * 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Center(child: _buildContent(showLoader, showCheck)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool showLoader, bool showCheck) {
    if (showCheck) {
      final t = CurvedAnimation(parent: _successPop, curve: Curves.elasticOut).value;
      return Transform.scale(
        scale: t.clamp(0.0, 1.2),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
      );
    }
    if (showLoader) {
      return const SizedBox(
        height: 26,
        width: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: Colors.white,
        ),
      );
    }
    return Text(
      widget.label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: 0.2,
      ),
    );
  }
}
