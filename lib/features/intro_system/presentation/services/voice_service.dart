import 'package:flutter/foundation.dart';

import 'intro_manager.dart';
import 'voice_welcome.dart';

/// Higher-level voice policy for intros.
class IntroVoiceService {
  static Future<void> maybeSpeakOncePerSession({
    required String message,
    required bool allow,
  }) async {
    if (!allow) return;
    if (kIsWeb) return;
    if (IntroManager.isVoiceMuted()) return;
    await VoiceWelcome.maybeSpeak(message);
  }
}

