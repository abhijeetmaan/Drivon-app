import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Horizontal shake for validation / auth errors.
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({super.key, required this.child});

  final Widget child;

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void shake() {
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dx = math.sin(t * math.pi * 7) * 12 * (1 - t);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
