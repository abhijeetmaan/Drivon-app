import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/theme/theme.dart';
import '../../auth_validators.dart';
import '../../data/repositories/hive_auth_repository.dart';
import '../../widgets/auth_ambient_background.dart';
import '../../widgets/auth_glass_form_card.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/shake_widget.dart';
import '../providers/auth_providers.dart';
import '../../../../shared/widgets/drivon_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _loginId = TextEditingController();
  final _password = TextEditingController();
  final _scroll = ScrollController();
  final _fnPassword = FocusNode();

  late AnimationController _master;
  late AnimationController _chipBreath;
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechReady = false;
  bool _voiceListening = false;
  bool _busy = false;
  bool _success = false;
  bool _demoPulseBtn = false;
  int _errorFlash = 0;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _chipBreath = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _master.forward();
    });
    unawaited(_initSpeech());
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _voiceListening = false;
            _speechReady = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speech: ${e.errorMsg}')));
        },
      );
      if (mounted) setState(() => _speechReady = ok);
    } catch (_) {
      if (mounted) setState(() => _speechReady = false);
    }
  }

  @override
  void dispose() {
    unawaited(_speech.stop());
    _master.dispose();
    _chipBreath.dispose();
    _scroll.dispose();
    _loginId.dispose();
    _password.dispose();
    _fnPassword.dispose();
    super.dispose();
  }

  Future<void> _toggleEmailVoice() async {
    if (_voiceListening) {
      await _speech.stop();
      if (mounted) setState(() => _voiceListening = false);
      return;
    }
    if (!_speechReady) await _initSpeech();
    if (!_speech.isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available on this device.')),
      );
      return;
    }
    final perm = await Permission.microphone.request();
    if (!perm.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required for voice input.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _voiceListening = true);
    HapticFeedback.mediumImpact();
    try {
      await _speech.listen(
        onResult: (res) {
          if (!mounted) return;
          setState(() {
            _loginId.text = res.recognizedWords;
            _loginId.selection = TextSelection.collapsed(offset: _loginId.text.length);
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      /* handled */
    }
    if (mounted) setState(() => _voiceListening = false);
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      setState(() => _errorFlash++);
      _shakeKey.currentState?.shake();
      return;
    }
    setState(() {
      _busy = true;
      _success = false;
    });
    try {
      final session = await ref.read(authProvider.notifier).attemptLogin(_loginId.text, _password.text);
      if (!mounted) return;
      if (session == null) {
        setState(() {
          _busy = false;
          _errorFlash++;
        });
        _shakeKey.currentState?.shake();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid email/phone or password.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
      setState(() {
        _busy = false;
        _success = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 920));
      if (!mounted) return;
      ref.read(authProvider.notifier).commitSession(session);
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _errorFlash++;
        _shakeKey.currentState?.shake();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _shakeKey.currentState?.shake();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
      }
    }
  }

  Future<void> _runDemoTyping() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    _loginId.clear();
    _password.clear();
    const email = HiveAuthRepository.demoEmail;
    const pass = HiveAuthRepository.demoPassword;
    for (var i = 0; i <= email.length; i++) {
      if (!mounted) return;
      setState(() => _loginId.text = email.substring(0, i));
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }
    await Future<void>.delayed(const Duration(milliseconds: 140));
    for (var i = 0; i <= pass.length; i++) {
      if (!mounted) return;
      setState(() => _password.text = pass.substring(0, i));
      await Future<void>.delayed(const Duration(milliseconds: 38));
    }
    if (!mounted) return;
    setState(() => _demoPulseBtn = true);
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _demoPulseBtn = false);
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final backdropFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0, 0.48, curve: Curves.easeOutCubic),
    );
    final headerEnter = CurvedAnimation(
      parent: _master,
      curve: const Interval(0, 0.52, curve: Curves.easeOutCubic),
    );
    final cardEnter = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
    );
    final headerFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.deferToChild,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: FadeTransition(
          opacity: backdropFade,
          child: AuthAmbientBackground(
            child: SafeArea(
              child: CustomScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 8),
                        Hero(
                          tag: 'auth_brand_chip',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withOpacity(0.08),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _chipBreath,
                                    builder: (context, child) {
                                      final s = 1 + 0.028 * math.sin(_chipBreath.value * math.pi * 2);
                                      return Transform.scale(scale: s, child: child);
                                    },
                                    child: DrivonLogo(size: 22, glow: true, pulse: 0.45),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Drivon',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        FadeTransition(
                          opacity: headerFade,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.1),
                              end: Offset.zero,
                            ).animate(headerEnter),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                        fontSize: 32,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Manage your vehicle smartly',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        AuthGlassFormCard(
                            entry: cardEnter,
                            child: ShakeWidget(
                              key: _shakeKey,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    CustomTextField(
                                      controller: _loginId,
                                      label: 'Email or phone',
                                      hint: 'you@email.com or mobile',
                                      icon: Icons.alternate_email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      validator: validateLoginId,
                                      errorFlashSeq: _errorFlash,
                                      voiceEnabled: true,
                                      voiceActive: _voiceListening,
                                      onVoiceTap: _busy || _success ? null : () => unawaited(_toggleEmailVoice()),
                                      onFieldSubmitted: (_) => _fnPassword.requestFocus(),
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _password,
                                      focusNode: _fnPassword,
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      textInputAction: TextInputAction.done,
                                      validator: validatePasswordLogin,
                                      errorFlashSeq: _errorFlash,
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                    const SizedBox(height: 18),
                                    _DemoLoginCard(onTap: _busy || _success ? null : _runDemoTyping),
                                    const SizedBox(height: 26),
                                    Hero(
                                      tag: 'auth_primary_cta',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: GradientAuthButton(
                                          label: 'Log in',
                                          isLoading: _busy,
                                          showSuccess: _success,
                                          demoPulse: _demoPulseBtn,
                                          onPressed: _busy || _success ? null : _submit,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ),
                        const SizedBox(height: 26),
                        Center(
                          child: TextButton(
                            onPressed: _busy || _success
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    context.push('/signup');
                                  },
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                children: [
                                  const TextSpan(text: "Don't have an account? "),
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      color: AppColors.accentCyan,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoLoginCard extends StatelessWidget {
  const _DemoLoginCard({this.onTap});

  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withOpacity(0.06),
          child: InkWell(
            onTap: onTap == null
                ? null
                : () async {
                    FocusScope.of(context).unfocus();
                    await onTap!();
                  },
            splashColor: AppColors.purple.withOpacity(0.2),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.purple.withOpacity(0.35),
                          AppColors.blue.withOpacity(0.25),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Try demo account',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${HiveAuthRepository.demoEmail}\nPassword: ${HiveAuthRepository.demoPassword}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.touch_app_rounded, color: AppColors.textSecondary.withOpacity(0.8)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
