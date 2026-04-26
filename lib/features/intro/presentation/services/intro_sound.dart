import 'package:flutter/services.dart';

/// Optional (OFF by default): tiny system sounds for “engine start / whoosh”.
///
/// If you later add real audio assets, this becomes the integration point.
abstract final class IntroSound {
  static bool enabled = false;

  static Future<void> engineStart() async {
    if (!enabled) return;
    SystemSound.play(SystemSoundType.alert);
  }

  static Future<void> whoosh() async {
    if (!enabled) return;
    SystemSound.play(SystemSoundType.click);
  }
}

