import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted glass panel with entry fade + scale (0.94 → 1).
class AuthGlassFormCard extends StatelessWidget {
  const AuthGlassFormCard({
    super.key,
    required this.entry,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 20),
  });

  final Animation<double> entry;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: entry, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.white.withOpacity(0.055),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
