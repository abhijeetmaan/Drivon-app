import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../motion/app_haptics.dart';
import '../motion/spring_interactive.dart';

/// Glassmorphism pill — frost, ripple, press scale + haptic.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.opacity = 0.10,
  });

  final VoidCallback onPressed;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double opacity;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.borderRadius);
    return SpringPressSurface(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            AppHaptics.tap();
            widget.onPressed();
          },
          borderRadius: r,
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: r,
                  color: Colors.white.withOpacity(widget.opacity.clamp(0.06, 0.14)),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  boxShadow: AppShadows.buttonSoft,
                ),
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
