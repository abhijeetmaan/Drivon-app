import 'package:flutter_tts/flutter_tts.dart';

import '../../../../shared/motion/app_haptics.dart';
import 'intro_manager.dart';

/// Voice greeting (soft) with mute + once-per-session control.
class VoiceWelcome {
  VoiceWelcome._();

  static FlutterTts? _tts;
  static bool _configured = false;

  static Future<void> _configureIfNeeded() async {
    if (_configured) return;
    _tts ??= FlutterTts();
    _configured = true;
    await _tts!.setSpeechRate(0.45);
    await _tts!.setVolume(0.55);
    await _tts!.setPitch(1.0);
  }

  static Future<void> maybeSpeak(String message) async {
    if (IntroManager.isVoiceMuted()) return;
    if (!IntroManager.shouldPlayVoiceThisSession()) return;
    await _configureIfNeeded();
    IntroManager.markVoicePlayedThisSession();
    AppHaptics.tap();
    await _tts!.stop();
    await _tts!.speak(message);
  }

  static Future<void> stop() async {
    if (!_configured || _tts == null) return;
    await _tts!.stop();
  }
}

