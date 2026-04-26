import 'package:flutter/material.dart';

/// Fade + slide-in with elastic ease (list reveal).
class StaggeredListEntry extends StatefulWidget {
  const StaggeredListEntry({
    super.key,
    required this.index,
    required this.child,
    this.delayPerIndex = const Duration(milliseconds: 38),
    this.duration = const Duration(milliseconds: 420),
  });

  final int index;
  final Widget child;
  final Duration delayPerIndex;
  final Duration duration;

  @override
  State<StaggeredListEntry> createState() => _StaggeredListEntryState();
}

class _StaggeredListEntryState extends State<StaggeredListEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    final delay = widget.delayPerIndex * widget.index;
    Future<void>.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOut);
        final slideT = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOut).value;
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - slideT)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Dismissible tuned for smoother motion.
class BouncyDismissible extends StatelessWidget {
  const BouncyDismissible({
    super.key,
    required this.dismissKey,
    required this.child,
    this.background,
    this.secondaryBackground,
    this.direction = DismissDirection.startToEnd,
    this.confirmDismiss,
    required this.onDismissed,
  });

  final Key dismissKey;
  final Widget child;
  final Widget? background;
  final Widget? secondaryBackground;
  final DismissDirection direction;
  final Future<bool?> Function(DismissDirection direction)? confirmDismiss;
  final void Function(DismissDirection direction) onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissKey,
      direction: direction,
      movementDuration: const Duration(milliseconds: 340),
      resizeDuration: const Duration(milliseconds: 320),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.28,
        DismissDirection.endToStart: 0.28,
      },
      background: background,
      secondaryBackground: secondaryBackground,
      confirmDismiss: confirmDismiss,
      onDismissed: onDismissed,
      child: child,
    );
  }
}
