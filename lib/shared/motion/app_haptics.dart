import 'package:flutter/services.dart';

/// Centralized haptics — consistent intensity across the app.
abstract final class AppHaptics {
  static void tap() => HapticFeedback.lightImpact();

  static void swipe() => HapticFeedback.selectionClick();

  static void confirm() => HapticFeedback.mediumImpact();

  /// Strong, short haptic for “complete / ignition” moments.
  static void strong() => HapticFeedback.heavyImpact();

  static void destructive() => HapticFeedback.mediumImpact();

  static void selection() => HapticFeedback.selectionClick();
}
