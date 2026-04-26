import 'dart:math' as math;

enum DayPhase { morning, afternoon, evening }

class GreetingService {
  static int _sessionRotation = 0;

  static DayPhase phaseFor(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h < 12) return DayPhase.morning;
    if (h >= 12 && h < 17) return DayPhase.afternoon;
    return DayPhase.evening;
  }

  static String phaseLabel(DayPhase p) {
    switch (p) {
      case DayPhase.morning:
        return 'morning';
      case DayPhase.afternoon:
        return 'afternoon';
      case DayPhase.evening:
        return 'evening';
    }
  }

  /// Rotates greeting templates (persisted) so it feels fresh.
  static String buildGreeting({
    required String userName,
    required DayPhase phase,
  }) {
    final name = userName.trim().isEmpty ? 'driver' : userName.trim();
    final templates = switch (phase) {
      DayPhase.morning => <String>[
          'Good morning, $name',
          'Morning, $name',
          'Ready for a new day, $name',
        ],
      DayPhase.afternoon => <String>[
          'Good afternoon, $name',
          'Welcome back, $name',
          'Good to see you, $name',
        ],
      DayPhase.evening => <String>[
          'Good evening, $name',
          'Welcome back, $name',
          'All set, $name',
        ],
    };

    // Session rotation avoids async writes during build (keeps widget tests stable).
    final next = (_sessionRotation + 1) % templates.length;
    _sessionRotation = next;

    // Tiny non-determinism while keeping a stable feel.
    final nudge = math.Random(DateTime.now().day + DateTime.now().hour).nextInt(templates.length);
    final idx = (next + nudge) % templates.length;
    return templates[idx];
  }
}

