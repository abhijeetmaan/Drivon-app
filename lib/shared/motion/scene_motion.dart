import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Drives subtle parallax for background + particles from scroll, touch, and nav.
/// Uses frame callbacks only while offsets are decaying (no idle ticker).
class SceneMotionController extends ChangeNotifier {
  Offset _touchNudge = Offset.zero;
  double _scrollImpulse = 0;
  double _navImpulse = 0;
  bool _ticking = false;

  static const double _touchDampen = 0.12;
  static const double _scrollGain = 0.0018;
  static const double _decayScroll = 0.88;
  static const double _decayNav = 0.86;
  static const double _decayTouch = 0.90;
  static const double _epsilon = 0.004;

  /// Normalized pointer position relative to [size] center; call on drag/move.
  void setTouchFromLocal(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    _touchNudge = Offset(
      ((local.dx - cx) / cx).clamp(-1.0, 1.0) * _touchDampen,
      ((local.dy - cy) / cy).clamp(-1.0, 1.0) * _touchDampen,
    );
    _ensureTick();
    notifyListeners();
  }

  void clearTouch() {
    _touchNudge = Offset.zero;
    notifyListeners();
  }

  void onScrollDelta(double delta) {
    if (delta == 0) return;
    _scrollImpulse = (_scrollImpulse * 0.82 + delta * _scrollGain).clamp(-1.4, 1.4);
    _ensureTick();
    notifyListeners();
  }

  /// Bottom-nav tab change: subtle horizontal kick (fromIndex - toIndex sign).
  void onTabChanged(int fromIndex, int toIndex) {
    final d = fromIndex - toIndex;
    if (d == 0) return;
    _navImpulse = (d > 0 ? 0.38 : -0.38);
    _ensureTick();
    notifyListeners();
  }

  /// Parallax in logical pixels for background layers (slow layer).
  Offset get backgroundParallax => Offset(
        _touchNudge.dx * 14 + _scrollImpulse * 10 + _navImpulse * 12,
        _touchNudge.dy * 10 - _scrollImpulse * 3,
      );

  /// Faster layer for particles (foreground of background stack).
  Offset get particleParallax => backgroundParallax * 1.35;

  void _ensureTick() {
    if (_ticking) return;
    _ticking = true;
    void frame(Duration _) {
      _scrollImpulse *= _decayScroll;
      _navImpulse *= _decayNav;
      _touchNudge = Offset(
        _touchNudge.dx * _decayTouch,
        _touchNudge.dy * _decayTouch,
      );

      if (_scrollImpulse.abs() < _epsilon) _scrollImpulse = 0;
      if (_navImpulse.abs() < _epsilon) _navImpulse = 0;
      if (_touchNudge.distance < _epsilon) _touchNudge = Offset.zero;

      notifyListeners();

      final active = _scrollImpulse.abs() > _epsilon ||
          _navImpulse.abs() > _epsilon ||
          _touchNudge.distance > _epsilon;
      if (active) {
        SchedulerBinding.instance.scheduleFrameCallback(frame);
      } else {
        _ticking = false;
      }
    }

    SchedulerBinding.instance.scheduleFrameCallback(frame);
  }

  @override
  void dispose() {
    _ticking = false;
    super.dispose();
  }
}
