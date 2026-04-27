import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/animated_entry.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../expenses/presentation/screens/expenses_screen.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../vehicle/presentation/providers/selected_vehicle_provider.dart';
import '../widgets/waveform.dart';

/// First numeric amount in the phrase, e.g. `"add fuel 1000"` → `1000`.
double? extractNumericAmount(String text) {
  final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text.toLowerCase());
  if (m == null) return null;
  return double.tryParse(m.group(1)!);
}

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _statusHint = 'Tap the mic and say a command, or use a chip below.';
  String _lastResponse = '';
  String? _initError;

  late final AnimationController _glowPulse;
  late final AnimationController _wave;

  static const Duration _uiTransition = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _glowPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    // Lazy init: initialize speech only when user taps the mic.
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onStatus: (_) {},
        onError: _onSpeechError,
      );
      if (!mounted) return;
      setState(() {
        _speechAvailable = ok;
        if (!ok) {
          _initError = _initError ?? 'Speech recognition is not available on this device.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _speechAvailable = false;
        _initError = e.toString();
      });
    }
  }

  void _onSpeechError(SpeechRecognitionError e) {
    if (!mounted) return;
    final msg = e.errorMsg;
    setState(() {
      _initError = msg;
      _isListening = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speech error: $msg')));
  }

  Future<bool> _ensureMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (status.isGranted) return true;
    if (!mounted) return false;
    final msg = status.isPermanentlyDenied
        ? 'Microphone access is blocked. Enable it in Settings to use voice.'
        : 'Microphone permission is required for voice commands.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: const SnackBarAction(label: 'Settings', onPressed: openAppSettings),
        duration: const Duration(seconds: 4),
      ),
    );
    return false;
  }

  Future<void> startListening() async {
    if (_isListening) return;

    final permitted = await _ensureMicPermission();
    if (!permitted) return;

    // Initialize only after user intent + permission.
    if (!_speech.isAvailable) {
      await _initSpeech();
    }
    if (!_speechAvailable || !_speech.isAvailable) {
      if (!mounted) return;
      final msg = _initError ?? 'Speech recognition is not available.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _statusHint = msg);
      return;
    }

    if (!mounted) return;
    setState(() {
      _recognizedText = '';
      _isListening = true;
      _statusHint = 'Listening… speak clearly.';
      _initError = null;
    });

    try {
      await _speech.listen(
        onResult: (res) {
          if (!mounted) return;
          setState(() => _recognizedText = res.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _statusHint = 'Could not start the microphone. Try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listen failed: $e')));
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    if (!mounted) return;
    setState(() => _isListening = false);

    final spoken = _recognizedText.trim();
    if (spoken.isEmpty) {
      setState(() => _statusHint = 'No speech detected. Tap the mic and try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No speech detected — try again or use a suggestion chip.')),
      );
      return;
    }

    await processCommand(spoken);
  }

  Future<void> _toggleMic() async {
    HapticFeedback.mediumImpact();
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// Parses voice / chip text and runs fuel, expense, navigation, or trip actions.
  Future<void> processCommand(String text) async {
    final raw = text.trim();
    if (raw.isEmpty) return;

    final cmd = raw.toLowerCase();
    final amount = extractNumericAmount(cmd);

    if (_matchesAddFuel(cmd) && amount != null) {
      final vid = defaultVehicleIdForNewData(ref);
      if (vid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add a vehicle first (required when scope is All vehicles).')),
          );
        }
        return;
      }
      await ref.read(expenseActionsProvider).addExpense(
            amount: amount,
            type: 'Fuel',
            date: DateTime.now(),
            note: 'Added via voice',
            vehicleId: vid,
          );
      if (!mounted) return;
      setState(() {
        _statusHint = 'Added fuel ₹$amount';
        _lastResponse = 'Added fuel ₹$amount';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added fuel expense ₹$amount')));
      return;
    }

    if (_matchesAddExpense(cmd) && amount != null) {
      final vid = defaultVehicleIdForNewData(ref);
      if (vid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add a vehicle first (required when scope is All vehicles).')),
          );
        }
        return;
      }
      await ref.read(expenseActionsProvider).addExpense(
            amount: amount,
            type: 'Service',
            date: DateTime.now(),
            note: 'Added via voice',
            vehicleId: vid,
          );
      if (!mounted) return;
      setState(() {
        _statusHint = 'Added expense ₹$amount';
        _lastResponse = 'Added expense ₹$amount';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added expense ₹$amount')));
      return;
    }

    if (_matchesShowExpenses(cmd)) {
      if (!mounted) return;
      setState(() {
        _statusHint = 'Opening expenses…';
        _lastResponse = 'Opening expenses';
      });
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpensesScreen()));
      return;
    }

    if (_matchesCreateTrip(cmd)) {
      final name = cmd.replaceFirst(RegExp(r'^.*?\btrip\b'), '').trim();
      final tripName = name.isEmpty ? await _askTripName() : name;
      if (tripName == null || tripName.trim().isEmpty) return;
      final vid = defaultVehicleIdForNewData(ref);
      if (vid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add a vehicle first (required when scope is All vehicles).')),
          );
        }
        return;
      }
      await ref.read(tripActionsProvider).createTrip(name: tripName.trim(), vehicleId: vid);
      if (!mounted) return;
      setState(() {
        _statusHint = 'Trip created';
        _lastResponse = 'Created trip: $tripName';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip created')));
      return;
    }

    if (!mounted) return;
    setState(() {
      _statusHint = 'Unrecognized command. Try the chips or say "add fuel 1000".';
      _lastResponse = 'Unrecognized: $raw';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unrecognized: "$raw"')));
  }

  bool _matchesAddFuel(String cmd) {
    return cmd.contains('fuel') && (cmd.contains('add') || cmd.contains('refuel') || cmd.contains('fill'));
  }

  bool _matchesAddExpense(String cmd) {
    if (cmd.contains('fuel')) return false;
    return (cmd.contains('expense') || cmd.contains('service') || cmd.contains('spent')) &&
        (cmd.contains('add') || cmd.contains('log') || cmd.contains('record'));
  }

  bool _matchesShowExpenses(String cmd) {
    return (cmd.contains('show') || cmd.contains('open') || cmd.contains('view')) && cmd.contains('expense');
  }

  bool _matchesCreateTrip(String cmd) {
    return cmd.contains('trip') && (cmd.contains('create') || cmd.contains('new') || cmd.contains('start'));
  }

  Future<String?> _askTripName() async {
    final controller = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trip name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'e.g. Goa ride'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    return res;
  }

  @override
  void dispose() {
    _glowPulse.dispose();
    _wave.dispose();
    unawaited(_speech.stop());
    super.dispose();
  }

  double _micBottomOffset(BuildContext context) {
    // Parent [AppShell] uses a Material 3 [NavigationBar] (~80) with [extendBody: true].
    const navBarHeight = 80.0;
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return navBarHeight + inset + 12;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final micBottom = _micBottomOffset(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Voice Assistant')),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 140 + bottomInset + micBottom),
            children: [
              AnimatedEntry(
                child: CustomCard(
                  prominent: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suggestions', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ActionChip(
                            label: const Text('add fuel 1000'),
                            onPressed: () => processCommand('add fuel 1000'),
                          ),
                          ActionChip(
                            label: const Text('add expense 500'),
                            onPressed: () => processCommand('add expense 500'),
                          ),
                          ActionChip(
                            label: const Text('show expenses'),
                            onPressed: () => processCommand('show expenses'),
                          ),
                          ActionChip(
                            label: const Text('create trip'),
                            onPressed: () => processCommand('create trip'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: _uiTransition,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => SlideTransition(
                          position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Text(_statusHint, key: ValueKey(_statusHint), style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      if (_initError != null) ...[
                        const SizedBox(height: 10),
                        Text(_initError!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error)),
                      ],
                      if (!_speechAvailable && _initError == null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Checking speech recognition…',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SectionHeader(title: 'Live transcription'),
              AnimatedContainer(
                duration: _uiTransition,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppLayout.radiusCard),
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: scheme.primary.withOpacity(0.22),
                            blurRadius: 18,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
                child: CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isListening) Waveform(animation: _wave, color: scheme.primary),
                      if (_isListening) const SizedBox(height: 8),
                      Text(
                        _recognizedText.isEmpty ? '—' : _recognizedText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _recognizedText.isEmpty ? scheme.outline : scheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SectionHeader(title: 'Response'),
              AnimatedSwitcher(
                duration: _uiTransition,
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _lastResponse.isEmpty
                    ? const SizedBox.shrink()
                    : CustomCard(
                        key: ValueKey(_lastResponse),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: scheme.primary.withOpacity(0.12),
                              child: const Icon(Icons.auto_awesome_outlined),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_lastResponse)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: micBottom,
            child: Center(
              child: _VoiceMicButton(
                listening: _isListening,
                glowPulse: _glowPulse,
                onPressed: _toggleMic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceMicButton extends StatelessWidget {
  const _VoiceMicButton({
    required this.listening,
    required this.glowPulse,
    required this.onPressed,
  });

  final bool listening;
  final Animation<double> glowPulse;
  final VoidCallback onPressed;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowPulse,
      builder: (context, _) {
        final pulseT = listening ? glowPulse.value : 0.0;
        final scale = listening ? 1.0 + 0.08 * pulseT : 1.0;
        final extraGlow = AppShadows.fabGlowPulseLayer(pulseT);

        return TweenAnimationBuilder<double>(
          key: ValueKey(listening),
          tween: Tween(begin: 1, end: listening ? 1.06 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (context, listenScale, child) {
            return Transform.scale(
              scale: scale * listenScale,
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Ink(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primary,
                  boxShadow: [...AppShadows.fabGlow, ...extraGlow],
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Icon(
                  listening ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: _size * 0.42,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
