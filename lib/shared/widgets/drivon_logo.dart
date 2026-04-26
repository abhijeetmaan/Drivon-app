import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

class DrivonLogo extends StatelessWidget {
  const DrivonLogo({
    super.key,
    this.size = 112,
    this.glow = true,
    this.pulse = 0.0,
    this.semanticLabel,
  });

  final double size;
  final bool glow;

  /// 0..1 recommended. When > 0, intensifies glow softly.
  final double pulse;

  final String? semanticLabel;

  static const String assetPath = 'assets/images/drivon_logo.png';

  @override
  Widget build(BuildContext context) {
    final p = pulse.clamp(0.0, 1.0);
    final glowAlpha = (0.24 + 0.20 * p).clamp(0.0, 0.55);
    final blur = 18.0 + 10.0 * p;

    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
    );

    if (!glow) return image;

    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: glowAlpha,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(AppColors.accentCyan.withOpacity(0.9), BlendMode.srcATop),
                child: image,
              ),
            ),
          ),
          image,
        ],
      ),
    );
  }
}

