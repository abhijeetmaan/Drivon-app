import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme.dart';
import '../services/device_motion_service.dart';

/// Wraps a card with subtle perspective tilt + moving gloss driven by device
/// motion. Rebuild scope is limited to [ListenableBuilder] (transform + gloss
/// only); [child] is kept stable.
class ImmersiveMotionLayer extends ConsumerStatefulWidget {
  const ImmersiveMotionLayer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppLayout.radiusCard)),
    this.gyroIntensity = 0.034,
    this.glossStrength = 0.42,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double gyroIntensity;
  final double glossStrength;

  @override
  ConsumerState<ImmersiveMotionLayer> createState() => _ImmersiveMotionLayerState();
}

class _ImmersiveMotionLayerState extends ConsumerState<ImmersiveMotionLayer> {
  late DeviceMotionService _motion;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _motion = ref.read(deviceMotionServiceProvider);
  }

  void _startIfNeeded() {
    if (_started) return;
    _started = true;
    _motion.start();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => _startIfNeeded(),
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: _motion,
          builder: (context, child) {
            final t = _motion.displayTilt;
            if (!_motion.sensorsAvailable) {
              return ClipRRect(borderRadius: widget.borderRadius, child: child!);
            }
            final gain = widget.gyroIntensity;
            final rotX = (-t.dy * gain).clamp(-0.045, 0.045);
            final rotY = (t.dx * gain * 1.05).clamp(-0.048, 0.048);
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.00075)
              ..rotateX(rotX)
              ..rotateY(rotY);
            final gloss = glossAlignmentsForTilt(
              scrollDelta: 0,
              deviceTilt: t,
              motionBlend: 1,
              focus: 0.85,
            );
            final g = widget.glossStrength;
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  fit: StackFit.passthrough,
                  children: [
                    child!,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Transform.translate(
                          offset: Offset(t.dx * 18, t.dy * 14),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: gloss.begin,
                                end: gloss.end,
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.045 * g),
                                  Colors.white.withOpacity(0.09 * g),
                                  AppColors.accentCyan.withOpacity(0.04 * g),
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.38, 0.48, 0.58, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
