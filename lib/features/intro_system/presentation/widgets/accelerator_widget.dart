import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/motion/app_haptics.dart';
import '../../../../shared/motion/spring_interactive.dart';

/// Big circular accelerator / ignition button.
class AcceleratorWidget extends StatefulWidget {
  const AcceleratorWidget({
    super.key,
    required this.onStart,
    this.enabled = true,
  });

  final VoidCallback onStart;
  final bool enabled;

  @override
  State<AcceleratorWidget> createState() => _AcceleratorWidgetState();
}

class _AcceleratorWidgetState extends State<AcceleratorWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 760));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _fire() async {
    if (!widget.enabled) return;
    AppHaptics.tap();
    _pulse.forward(from: 0);
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_pulse.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              if (t > 0)
                Container(
                  width: 220 + 120 * t,
                  height: 220 + 120 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentCyan.withOpacity(0.20 * (1 - t)),
                        AppColors.purple.withOpacity(0.16 * (1 - t)),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              child!,
            ],
          );
        },
        child: SpringPressSurface(
          enabled: widget.enabled,
          pressedScale: 0.96,
          child: GestureDetector(
            onTap: _fire,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.card.withOpacity(0.92),
                    AppColors.surface.withOpacity(0.88),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 44,
                    offset: const Offset(0, 24),
                    spreadRadius: -10,
                  ),
                  BoxShadow(
                    color: AppColors.purple.withOpacity(0.18),
                    blurRadius: 42,
                    offset: const Offset(0, 18),
                    spreadRadius: -14,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentCyan.withOpacity(0.20),
                          blurRadius: 28,
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      color: Colors.white.withOpacity(0.96),
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tap to Start',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Press to start engine',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

