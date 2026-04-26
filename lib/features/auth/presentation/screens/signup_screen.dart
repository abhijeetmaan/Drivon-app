import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../auth_validators.dart';
import '../../widgets/auth_ambient_background.dart';
import '../../widgets/auth_glass_form_card.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/shake_widget.dart';
import '../providers/auth_providers.dart';
import '../../../../shared/widgets/drivon_logo.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _name = TextEditingController();
  final _loginId = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _scroll = ScrollController();
  final _fnName = FocusNode();
  final _fnLogin = FocusNode();
  final _fnPass = FocusNode();
  final _fnConfirm = FocusNode();

  late AnimationController _master;
  late AnimationController _chipBreath;

  bool _busy = false;
  bool _success = false;
  int _errorFlash = 0;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(vsync: this, duration: const Duration(milliseconds: 960));
    _chipBreath = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _master.forward();
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _chipBreath.dispose();
    _scroll.dispose();
    _name.dispose();
    _loginId.dispose();
    _password.dispose();
    _confirm.dispose();
    _fnName.dispose();
    _fnLogin.dispose();
    _fnPass.dispose();
    _fnConfirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() => _errorFlash++);
      _shakeKey.currentState?.shake();
      return;
    }
    setState(() {
      _busy = true;
      _success = false;
    });
    try {
      final session = await ref.read(authProvider.notifier).attemptSignup(
            name: _name.text,
            loginId: _loginId.text,
            password: _password.text,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _success = true;
      });
      HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 920));
      if (!mounted) return;
      ref.read(authProvider.notifier).commitSession(session);
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _errorFlash++;
        });
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final topPad = MediaQuery.paddingOf(context).top;

    final backdropFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0, 0.48, curve: Curves.easeOutCubic),
    );
    final headerEnter = CurvedAnimation(
      parent: _master,
      curve: const Interval(0, 0.52, curve: Curves.easeOutCubic),
    );
    final headerFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    final cardEnter = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
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
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(8, topPad > 0 ? 4 : 8, 16, 8),
                    child: Row(
                      children: [
                        ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Material(
                              color: Colors.white.withOpacity(0.08),
                              child: IconButton(
                                onPressed: _busy || _success ? null : () => context.pop(),
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Hero(
                          tag: 'auth_brand_chip',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                    child: DrivonLogo(size: 20, glow: true, pulse: 0.45),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Drivon',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.7,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 32),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              FadeTransition(
                                opacity: headerFade,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, -0.08),
                                    end: Offset.zero,
                                  ).animate(headerEnter),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Create account',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                              fontSize: 30,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Join and manage every ride in one place',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: AppColors.textSecondary,
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
                                          controller: _name,
                                          focusNode: _fnName,
                                          label: 'Name',
                                          hint: 'Your full name',
                                          icon: Icons.person_outline_rounded,
                                          textCapitalization: TextCapitalization.words,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                                          errorFlashSeq: _errorFlash,
                                          onFieldSubmitted: (_) => _fnLogin.requestFocus(),
                                        ),
                                        const SizedBox(height: 16),
                                        CustomTextField(
                                          controller: _loginId,
                                          focusNode: _fnLogin,
                                          label: 'Email or phone',
                                          hint: 'you@email.com or mobile',
                                          icon: Icons.alternate_email_rounded,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          validator: validateLoginId,
                                          errorFlashSeq: _errorFlash,
                                          onFieldSubmitted: (_) => _fnPass.requestFocus(),
                                        ),
                                        const SizedBox(height: 16),
                                        CustomTextField(
                                          controller: _password,
                                          focusNode: _fnPass,
                                          label: 'Password',
                                          icon: Icons.lock_outline_rounded,
                                          isPassword: true,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) => validatePasswordSignup(v, minLength: 6),
                                          errorFlashSeq: _errorFlash,
                                          onFieldSubmitted: (_) => _fnConfirm.requestFocus(),
                                        ),
                                        const SizedBox(height: 16),
                                        CustomTextField(
                                          controller: _confirm,
                                          focusNode: _fnConfirm,
                                          label: 'Confirm password',
                                          icon: Icons.verified_user_outlined,
                                          isPassword: true,
                                          textInputAction: TextInputAction.done,
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Confirm your password';
                                            if (v != _password.text) return 'Passwords do not match';
                                            return null;
                                          },
                                          errorFlashSeq: _errorFlash,
                                          onFieldSubmitted: (_) => _submit(),
                                        ),
                                        const SizedBox(height: 28),
                                        Hero(
                                          tag: 'auth_primary_cta',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: GradientAuthButton(
                                              label: 'Create account',
                                              isLoading: _busy,
                                              showSuccess: _success,
                                              onPressed: _busy || _success ? null : _submit,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: TextButton(
                                  onPressed: _busy || _success
                                      ? null
                                      : () {
                                          FocusScope.of(context).unfocus();
                                          context.pop();
                                        },
                                  child: RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                      children: [
                                        const TextSpan(text: 'Already have an account? '),
                                        TextSpan(
                                          text: 'Log in',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
