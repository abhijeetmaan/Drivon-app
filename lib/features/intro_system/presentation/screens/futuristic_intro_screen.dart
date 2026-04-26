import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../features/profile/presentation/providers/profile_providers.dart';
import '../../../../features/intro/presentation/widgets/car_animation_widget.dart';
import '../../../../features/vehicle/presentation/providers/selected_vehicle_provider.dart';
import '../../../../features/vehicle/presentation/providers/vehicle_providers.dart';
import '../../../../shared/motion/app_haptics.dart';
import '../../../../shared/motion/scene_motion.dart';
import '../../../../shared/widgets/animated_background.dart';
import '../../../../shared/widgets/subtle_particle_field.dart';
import '../services/greeting_service.dart';
import '../services/intro_ai_engine.dart';
import '../services/intro_manager.dart';
import '../services/voice_service.dart';
import '../services/weather_service.dart';
import '../widgets/accelerator_widget.dart';
import '../widgets/speedometer_widget.dart';
import '../../../../shared/widgets/drivon_logo.dart';

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Futuristic “gamified ignition” intro with smart repetition control.
class FuturisticIntroScreen extends ConsumerStatefulWidget {
  const FuturisticIntroScreen({super.key});

  @override
  ConsumerState<FuturisticIntroScreen> createState() => _FuturisticIntroScreenState();
}

class _FuturisticIntroScreenState extends ConsumerState<FuturisticIntroScreen> with TickerProviderStateMixin {
  late final IntroVariant _variant;
  late final SceneMotionController _scene;

  AnimationController? _seq;
  Timer? _autoAdvance;
  WeatherInfo? _weather;

  bool _started = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _variant = IntroManager.decideVariant();
    _scene = SceneMotionController();

    // Best-effort weather: cached first, network refresh async (non-blocking).
    _weather = WeatherService.readCachedSync();
    WeatherService.fetchAndCacheBestEffort().then((w) {
      if (!mounted) return;
      if (w == null) return;
      setState(() => _weather = w);
    });

    if (_variant == IntroVariant.short) {
      _started = true;
      _runSequence(durationMs: 1050);
      _autoAdvance = Timer(const Duration(milliseconds: 1150), _finish);
    }
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _seq?.dispose();
    _scene.dispose();
    super.dispose();
  }

  void _runSequence({required int durationMs}) {
    _seq?.dispose();
    _seq = AnimationController(vsync: this, duration: Duration(milliseconds: durationMs))
      ..addListener(_syncHaptics)
      ..forward();
  }

  bool _carHaptic = false;
  bool _engineHaptic = false;
  bool _doneHaptic = false;
  void _syncHaptics() {
    final t = _seq?.value ?? 0;
    if (!_engineHaptic && t > 0.06) {
      _engineHaptic = true;
      AppHaptics.confirm();
    }
    if (!_carHaptic && t > 0.22) {
      _carHaptic = true;
      AppHaptics.tap();
    }
    if (!_doneHaptic && t > 0.92) {
      _doneHaptic = true;
      AppHaptics.strong();
    }
  }

  void _start() {
    if (_started) return;
    setState(() => _started = true);
    _runSequence(durationMs: 2150);
    IntroManager.markIntroShown(full: true);
    _autoAdvance = Timer(const Duration(milliseconds: 2300), _finish);
    // Voice is dynamic and context-aware; it also respects mute + once/session.
    final ai = _buildAiOutput();
    IntroVoiceService.maybeSpeakOncePerSession(
      message: ai.voiceLine,
      allow: _variant == IntroVariant.full,
    );
  }

  void _skip() {
    AppHaptics.selection();
    _finish();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    IntroManager.markIntroShown(full: _variant == IntroVariant.full);
    if (!mounted) return;
    // Yield to the router chain: it will redirect to login/onboarding/home based on auth state.
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final seq = _seq;
    final t = seq?.value ?? 0.0;

    final ai = _buildAiOutput();

    final dashboardGlow = Curves.easeOutCubic.transform(((t - 0.06) / 0.16).clamp(0.0, 1.0));
    final meterT = Curves.easeOutCubic.transform(((t - 0.14) / 0.62).clamp(0.0, 1.0));
    final carT = Curves.easeOutCubic.transform(((t - 0.18) / 0.62).clamp(0.0, 1.0));
    final zoomIn = Curves.easeInCubic.transform(((t - 0.88) / 0.12).clamp(0.0, 1.0));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (e) => _scene.setTouchFromLocal(e.localPosition, size),
        onPointerUp: (_) => _scene.clearTouch(),
        onPointerCancel: (_) => _scene.clearTouch(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBackground(motion: _scene),
            SubtleParticleField(motion: _scene, particleCount: 24),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _toneFor(ai: ai),
                    ),
                  ),
                ),
              ),
            ),
            if (_started)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.35 * dashboardGlow,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.1),
                          radius: 1.0,
                          colors: [
                            AppColors.accentCyan.withOpacity(0.18),
                            AppColors.purple.withOpacity(0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _VoiceToggle(
                          muted: IntroManager.isVoiceMuted(),
                          onToggle: (v) async {
                            await IntroManager.setVoiceMuted(v);
                            setState(() {});
                          },
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _skip,
                          child: Text(
                            'Skip',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AnimatedScale(
                      scale: 1.0 + 0.02 * zoomIn,
                      duration: Duration.zero,
                      child: Column(
                        children: [
                          if (_started) ...[
                            CarAnimationWidget(t: carT, width: math.min(360, size.width - 32)),
                            const SizedBox(height: 22),
                            Opacity(
                              opacity: meterT,
                              child: SpeedometerWidget(progress: meterT, size: math.min(220, size.width * 0.62)),
                            ),
                          ] else ...[
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => Opacity(
                                opacity: v,
                                child: Transform.scale(
                                  scale: 0.92 + 0.08 * v,
                                  child: DrivonLogo(
                                    size: 118,
                                    glow: true,
                                    pulse: 0.55 + 0.35 * math.sin(DateTime.now().millisecond / 1000 * math.pi),
                                    semanticLabel: 'Drivon',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              ai.headline,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ai.subline,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 28),
                            AcceleratorWidget(onStart: _start),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_started)
                      Opacity(
                        opacity: Curves.easeOut.transform(((t - 0.42) / 0.22).clamp(0.0, 1.0)),
                        child: Text(
                          _variant == IntroVariant.full ? _bootLine(ai) : 'Ready…',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_started)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.18 * zoomIn,
                    child: ColoredBox(color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IntroAiOutput _buildAiOutput() {
    final profile = ref.read(profileProvider).valueOrNull;
    final name = profile?.name ?? '';
    final scope = ref.read(selectedVehicleIdProvider);
    final vehicles = ref.read(vehiclesProvider).valueOrNull ?? const [];
    final selected = vehicles.where((v) => v.id == scope).firstOrNull;
    return IntroAiEngine.build(
      userName: name,
      now: DateTime.now(),
      weather: _weather,
      selectedVehicle: selected,
    );
  }

  LinearGradient _toneFor({required IntroAiOutput ai}) {
    // Subtle background tone shift based on time + weather. Keeps readability.
    final baseTop = switch (ai.dayPhase) {
      DayPhase.morning => const Color(0xFF1B1A2B),
      DayPhase.afternoon => const Color(0xFF101A2E),
      DayPhase.evening => const Color(0xFF0B1020),
    };
    final wx = switch (ai.weatherKind) {
      WeatherKind.sunny => AppColors.accentOrange.withOpacity(0.10),
      WeatherKind.cloudy => Colors.white.withOpacity(0.06),
      WeatherKind.rainy => AppColors.blue.withOpacity(0.10),
      WeatherKind.unknown => AppColors.purple.withOpacity(0.08),
    };
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseTop.withOpacity(0.0),
        wx,
        Colors.transparent,
      ],
      stops: const [0.0, 0.48, 1.0],
    );
  }

  String _bootLine(IntroAiOutput ai) {
    if (ai.vehicleName != null) return 'Booting ${ai.vehicleName} insights…';
    return 'Booting vehicle insights…';
  }
}

class _VoiceToggle extends StatelessWidget {
  const _VoiceToggle({required this.muted, required this.onToggle});

  final bool muted;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onToggle(!muted),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              muted ? 'Voice off' : 'Voice on',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

