import 'package:flutter/material.dart';

import '../motion/app_haptics.dart';
import '../motion/spring_interactive.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  /// Merged with theme; use for form CTAs (e.g. full-width minimum height, pill shape).
  final ButtonStyle? style;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SpringPressSurface(
      enabled: !isLoading && onPressed != null,
      child: FilledButton(
        style: style,
        onPressed: isLoading
            ? null
            : () {
                AppHaptics.tap();
                onPressed?.call();
              },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label, key: const ValueKey('label')),
        ),
      ),
    );
  }
}
