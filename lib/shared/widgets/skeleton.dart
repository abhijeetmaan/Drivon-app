import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Shimmer placeholder — rounded, matches card radii.
class Skeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.card;
    final hi = Colors.white.withOpacity(0.08);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.2 + 2.4 * t, 0),
              end: Alignment(0.2 + 2.4 * t, 0),
              colors: [base, Color.lerp(base, hi, 0.35)!, base],
            ),
          ),
        );
      },
    );
  }
}
