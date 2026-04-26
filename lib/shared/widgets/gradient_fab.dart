import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme.dart';

/// Circular primary action — gradient, glow, slow pulse, haptic.
class GradientFab extends StatefulWidget {
  const GradientFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.size = 56,
    this.tooltip,
    this.pulse = true,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final String? tooltip;
  final bool pulse;

  @override
  State<GradientFab> createState() => _GradientFabState();
}

class _GradientFabState extends State<GradientFab> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  void _fire() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  Widget _buildFab(double pulseT) {
    final glow = [
      ...AppShadows.fabGlow,
      ...AppShadows.fabGlowPulseLayer(pulseT),
    ];
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: AppMotion.pressScale,
        curve: AppMotion.pressCurve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _fire,
            splashColor: Colors.white30,
            highlightColor: Colors.white12,
            child: Ink(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: glow,
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.4),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = _pulse != null
        ? AnimatedBuilder(
            animation: _pulse!,
            builder: (_, __) => _buildFab(_pulse!.value),
          )
        : _buildFab(0.38);

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// Extended gradient CTA — glow + haptic + press scale.
class GradientExtendedFab extends StatefulWidget {
  const GradientExtendedFab({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add_rounded,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final String? tooltip;

  @override
  State<GradientExtendedFab> createState() => _GradientExtendedFabState();
}

class _GradientExtendedFabState extends State<GradientExtendedFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _fire() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(28);
    final button = AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = [...AppShadows.fabGlow, ...AppShadows.fabGlowPulseLayer(_pulse.value * 0.65)];
        return Listener(
          onPointerDown: (_) => setState(() => _down = true),
          onPointerUp: (_) => setState(() => _down = false),
          onPointerCancel: (_) => setState(() => _down = false),
          child: AnimatedScale(
            scale: _down ? 0.95 : 1.0,
            duration: AppMotion.pressScale,
            curve: AppMotion.pressCurve,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: r,
                onTap: _fire,
                splashColor: Colors.white30,
                highlightColor: Colors.white12,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    gradient: AppGradients.primary,
                    boxShadow: glow,
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
