import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ??
        const [AppColors.purple, AppColors.blue];
    final r = BorderRadius.circular(AppLayout.radiusCard);

    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          ...AppShadows.cardRaised,
          BoxShadow(
            color: AppColors.purple.withOpacity(0.18),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.white.withOpacity(0.04),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: r,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: content,
      ),
    );
  }
}
