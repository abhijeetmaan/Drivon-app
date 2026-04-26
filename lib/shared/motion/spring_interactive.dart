import 'package:flutter/material.dart';

/// Press scale: quick ease-out press, gentle easeOutBack on release.
class SpringPressSurface extends StatefulWidget {
  const SpringPressSurface({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
    this.pressDuration = const Duration(milliseconds: 200),
    this.releaseDuration = const Duration(milliseconds: 360),
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;
  final Duration pressDuration;
  final Duration releaseDuration;

  @override
  State<SpringPressSurface> createState() => _SpringPressSurfaceState();
}

class _SpringPressSurfaceState extends State<SpringPressSurface> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.pressDuration);
    _rebuildScaleAnimation();
  }

  void _rebuildScaleAnimation() {
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _c,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SpringPressSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressDuration != widget.pressDuration) {
      _c.duration = widget.pressDuration;
    }
    if (oldWidget.pressedScale != widget.pressedScale) {
      _rebuildScaleAnimation();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() {
    _c.duration = widget.pressDuration;
    _c.forward();
  }

  void _up() {
    _c.duration = widget.releaseDuration;
    _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      onPointerDown: (_) => _down(),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
