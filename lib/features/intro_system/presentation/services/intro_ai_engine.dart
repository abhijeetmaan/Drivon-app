import '../../../../features/vehicle/domain/entities/vehicle.dart';
import 'greeting_service.dart';
import 'weather_service.dart';

enum IntroMotionMood { calm, sport }

class IntroAiOutput {
  final String headline;
  final String subline;
  final String voiceLine;
  final IntroMotionMood mood;
  final WeatherKind weatherKind;
  final DayPhase dayPhase;
  final String? vehicleName;

  const IntroAiOutput({
    required this.headline,
    required this.subline,
    required this.voiceLine,
    required this.mood,
    required this.weatherKind,
    required this.dayPhase,
    required this.vehicleName,
  });
}

class IntroAiEngine {
  static IntroAiOutput build({
    required String userName,
    required DateTime now,
    required WeatherInfo? weather,
    required Vehicle? selectedVehicle,
  }) {
    final phase = GreetingService.phaseFor(now);
    final greeting = GreetingService.buildGreeting(userName: userName, phase: phase);

    final vName = selectedVehicle?.name.trim().isEmpty == false ? selectedVehicle!.name.trim() : null;
    final mood = _moodForVehicle(selectedVehicle);

    final weatherKind = weather?.kind ?? WeatherKind.unknown;
    final weatherLine = _weatherSentence(weather);
    final vehicleLine = vName == null ? null : 'Your $vName is ready.';

    final voice = [
      '$greeting.',
      if (weatherLine != null) weatherLine,
      if (vehicleLine != null) vehicleLine,
      'All systems ready.',
    ].join(' ');

    final sub = [
      if (vName != null) vName,
      _phaseTagline(phase, mood),
    ].where((s) => s.trim().isNotEmpty).join(' · ');

    return IntroAiOutput(
      headline: greeting,
      subline: sub,
      voiceLine: voice,
      mood: mood,
      weatherKind: weatherKind,
      dayPhase: phase,
      vehicleName: vName,
    );
  }

  static IntroMotionMood _moodForVehicle(Vehicle? v) {
    if (v == null) return IntroMotionMood.calm;
    final s = '${v.name} ${v.model} ${v.fuelType}'.toLowerCase();
    const sportHints = ['sport', 'rs', 'gt', 'turbo', 'track', 'performance'];
    if (sportHints.any(s.contains)) return IntroMotionMood.sport;
    return IntroMotionMood.calm;
  }

  static String _phaseTagline(DayPhase phase, IntroMotionMood mood) {
    return switch (phase) {
      DayPhase.morning => mood == IntroMotionMood.sport ? 'Warm-up complete' : 'Soft start',
      DayPhase.afternoon => mood == IntroMotionMood.sport ? 'Peak mode' : 'Cruise mode',
      DayPhase.evening => mood == IntroMotionMood.sport ? 'Night drive' : 'Calm drive',
    };
  }

  static String? _weatherSentence(WeatherInfo? w) {
    if (w == null || w.kind == WeatherKind.unknown) return null;
    return switch (w.kind) {
      WeatherKind.sunny => 'It\'s sunny today — perfect for a drive.',
      WeatherKind.cloudy => 'Cloudy skies today — smooth roads ahead.',
      WeatherKind.rainy => 'Rainy weather today — drive safe.',
      WeatherKind.unknown => null,
    };
  }
}

