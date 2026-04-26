import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';

const String kHasSeenFullIntroKey = 'has_seen_full_intro_v1';
const String kIntroLastShownMsKey = 'intro_last_shown_ms_v1';
const String kIntroMuteKey = 'intro_voice_muted_v1';

enum IntroVariant { full, short }

/// Smart intro logic: full once, short thereafter.
class IntroManager {
  static bool _voicePlayedThisSession = false;

  static Box<dynamic>? _prefsBoxOrNull() {
    if (!Hive.isBoxOpen(HiveBoxes.appPrefs)) return null;
    return Hive.box<dynamic>(HiveBoxes.appPrefs);
  }

  static IntroVariant decideVariant() {
    final box = _prefsBoxOrNull();
    if (box == null) return IntroVariant.full;
    final seen = box.get(kHasSeenFullIntroKey) == true;
    return seen ? IntroVariant.short : IntroVariant.full;
  }

  static bool isVoiceMuted() {
    final box = _prefsBoxOrNull();
    if (box == null) return true; // fail-closed: no voice.
    return box.get(kIntroMuteKey) == true;
  }

  static Future<void> setVoiceMuted(bool muted) async {
    final box = _prefsBoxOrNull();
    if (box == null) return;
    await box.put(kIntroMuteKey, muted);
  }

  static bool shouldPlayVoiceThisSession() => !_voicePlayedThisSession;

  static void markVoicePlayedThisSession() {
    _voicePlayedThisSession = true;
  }

  static Future<void> markIntroShown({required bool full}) async {
    final box = _prefsBoxOrNull();
    if (box == null) return;
    await box.put(kIntroLastShownMsKey, DateTime.now().millisecondsSinceEpoch);
    if (full) {
      await box.put(kHasSeenFullIntroKey, true);
    }
  }

  @visibleForTesting
  static void resetSessionForTests() {
    _voicePlayedThisSession = false;
  }
}

