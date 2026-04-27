import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Smoothed device tilt for premium 3D UI. Uses accelerometer (gravity vector)
/// with a lightly blended gyroscope high-pass layer. Fails closed (zero tilt)
/// when sensors are unavailable.
class DeviceMotionService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _ax = 0;
  double _ay = 0;
  double _gx = 0;
  double _gy = 0;

  /// Normalized tilt in roughly [-0.48, 0.48] for UI mapping.
  Offset displayTilt = Offset.zero;

  bool sensorsAvailable = false;
  bool _running = false;

  static const double _gravityRef = 9.81;
  static const double _accelLerp = 0.14;
  static const double _gyroLerp = 0.12;
  static const double _gyroScale = 0.00042;
  static const double _clampTilt = 0.48;

  int _lastEmitMs = 0;
  static const int _minEmitIntervalMs = 14;

  void start() {
    if (_running) return;
    _running = true;
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onAccel, onError: (_) => _markUnavailable());
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onGyro, onError: (_) {});
      sensorsAvailable = true;
    } catch (_) {
      _markUnavailable();
    }
  }

  void _markUnavailable() {
    sensorsAvailable = false;
    displayTilt = Offset.zero;
    _safeNotify();
  }

  void _onAccel(AccelerometerEvent e) {
    if (!sensorsAvailable) return;
    final nx = (e.x / _gravityRef).clamp(-1.2, 1.2) * 0.52;
    final ny = (e.y / _gravityRef).clamp(-1.2, 1.2) * 0.52;
    _ax = _ax * (1 - _accelLerp) + nx * _accelLerp;
    _ay = _ay * (1 - _accelLerp) + ny * _accelLerp;
    _recomputeTilt();
  }

  void _onGyro(GyroscopeEvent e) {
    if (!sensorsAvailable) return;
    final rx = e.x * _gyroScale;
    final ry = e.y * _gyroScale;
    _gx = _gx * (1 - _gyroLerp) + rx * _gyroLerp;
    _gy = _gy * (1 - _gyroLerp) + ry * _gyroLerp;
    _recomputeTilt();
  }

  void _recomputeTilt() {
    final tx = (_ax + _gx * 0.35).clamp(-_clampTilt, _clampTilt);
    final ty = (_ay + _gy * 0.35).clamp(-_clampTilt, _clampTilt);
    displayTilt = Offset(tx, ty);
    _throttledNotify();
  }

  void _throttledNotify() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastEmitMs < _minEmitIntervalMs) return;
    _lastEmitMs = now;
    _safeNotify();
  }

  void _safeNotify() {
    if (hasListeners) notifyListeners();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }
}

final deviceMotionServiceProvider = ChangeNotifierProvider<DeviceMotionService>((ref) {
  final service = DeviceMotionService();
  ref.onDispose(service.dispose);
  // Important: don't start sensors during bootstrap / before runApp().
  // Widgets that actually render motion effects should call `start()`.
  return service;
});

/// While the carousel scroll position reports active scrolling, suppress gyro
/// so swipe + sensor motion do not fight.
double carouselMotionBlend({
  required bool metricsReady,
  required ScrollPosition? position,
}) {
  if (!metricsReady || position == null) return 1.0;
  if (position.isScrollingNotifier.value) return 0.0;
  return 1.0;
}

/// Extra rotation radians from device (x → pitch, y → yaw feel on card).
Offset deviceRotationForCard({
  required Offset deviceTilt,
  required double motionBlend,
  required double focus,
  required double deviceGain,
}) {
  final mb = motionBlend * deviceGain * (0.28 + 0.72 * focus);
  final rotX = (-deviceTilt.dy * 0.055 * mb).clamp(-0.06, 0.06);
  final rotY = (deviceTilt.dx * 0.062 * mb).clamp(-0.065, 0.065);
  return Offset(rotX, rotY);
}

/// Moving gloss band: begin / end alignments from swipe + tilt.
({Alignment begin, Alignment end}) glossAlignmentsForTilt({
  required double scrollDelta,
  required Offset deviceTilt,
  required double motionBlend,
  required double focus,
}) {
  final mb = motionBlend * (0.4 + 0.6 * focus);
  final gx = deviceTilt.dx * 0.38 * mb;
  final gy = deviceTilt.dy * 0.32 * mb;
  final bx = (-0.92 + gx + scrollDelta * 0.24).clamp(-1.0, 1.0);
  final by = (-0.88 + gy + scrollDelta.abs() * 0.06).clamp(-1.0, 1.0);
  final ex = (0.82 - gx * 0.55 + scrollDelta * 0.1).clamp(-1.0, 1.0);
  final ey = (0.9 - gy * 0.45).clamp(-1.0, 1.0);
  return (begin: Alignment(bx, by), end: Alignment(ex, ey));
}
