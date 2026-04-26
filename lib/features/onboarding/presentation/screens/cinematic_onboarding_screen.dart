import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/motion/app_haptics.dart';
import '../../../../shared/motion/scene_motion.dart';
import '../../../../shared/services/onboarding_prefs.dart';
import '../../../../shared/widgets/animated_background.dart';
import '../../../../shared/widgets/subtle_particle_field.dart';

/// Four-step cinematic intro: logo, dashboard, expenses, insights.
class CinematicOnboardingScreen extends StatefulWidget {
  const CinematicOnboardingScreen({super.key});

  @override
  State<CinematicOnboardingScreen> createState() => _CinematicOnboardingScreenState();
}

class _CinematicOnboardingScreenState extends State<CinematicOnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final SceneMotionController _scene;
  int _page = 0;
  static const _totalPages = 4;

  late AnimationController _logoReveal;

  @override
  void initState() {
    super.initState();
    _scene = SceneMotionController();
    _logoReveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 920));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _logoReveal.forward();
    });
  }

  @override
  void dispose() {
    _logoReveal.dispose();
    _scene.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    AppHaptics.confirm();
    await writeOnboardingCompleted();
    if (!mounted) return;
    context.go('/');
  }

  void _next() {
    AppHaptics.tap();
    if (_page >= _totalPages - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: (e) => _scene.setTouchFromLocal(e.localPosition, size),
            onPointerUp: (_) => _scene.clearTouch(),
            onPointerCancel: (_) => _scene.clearTouch(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBackground(motion: _scene),
                SubtleParticleField(motion: _scene, particleCount: 36),
                NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification) {
                      final d = n.scrollDelta ?? 0.0;
                      if (n.metrics.axis == Axis.vertical) {
                        _scene.onScrollDelta(d);
                      } else if (n.metrics.axis == Axis.horizontal) {
                        _scene.onScrollDelta(-d * 0.35);
                      }
                    }
                    return false;
                  },
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) {
                      AppHaptics.swipe();
                      _scene.onTabChanged(_page, i);
                      setState(() => _page = i);
                    },
                    children: [
                      _OnboardLogoPage(reveal: _logoReveal),
                      const _OnboardCopyPage(
                        title: 'Track your vehicles smartly',
                        subtitle: 'One dashboard for every vehicle, trip, and document.',
                        child: _DashboardPreviewCard(),
                      ),
                      const _OnboardCopyPage(
                        title: 'Understand your expenses',
                        subtitle: 'See where your money goes with clarity, not clutter.',
                        child: _ExpenseChartPreview(),
                      ),
                      const _OnboardCopyPage(
                        title: 'Get smart insights',
                        subtitle: 'Trends and signals that help you decide what matters next.',
                        child: _InsightsPreviewCard(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16 + bottomInset,
                  child: _OnboardChrome(
                    page: _page,
                    total: _totalPages,
                    onSkip: _finish,
                    onContinue: _next,
                    continueLabel: _page >= _totalPages - 1 ? 'Get started' : 'Continue',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OnboardChrome extends StatelessWidget {
  const _OnboardChrome({
    required this.page,
    required this.total,
    required this.onSkip,
    required this.onContinue,
    required this.continueLabel,
  });

  final int page;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            AppHaptics.selection();
            onSkip();
          },
          child: Text(
            'Skip',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: active
                      ? AppColors.accentCyan.withOpacity(0.9)
                      : Colors.white.withOpacity(0.18),
                ),
              );
            }),
          ),
        ),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: const StadiumBorder(),
          ),
          child: Text(continueLabel),
        ),
      ],
    );
  }
}

class _OnboardLogoPage extends StatelessWidget {
  const _OnboardLogoPage({required this.reveal});

  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 120),
        child: AnimatedBuilder(
          animation: reveal,
          builder: (context, child) {
            final t = CurvedAnimation(parent: reveal, curve: Curves.easeOutCubic).value;
            final glow = CurvedAnimation(parent: reveal, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)).value;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 0.86 + 0.14 * t,
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                SizedBox(height: 28 * t),
                Opacity(
                  opacity: (t * 1.15).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - t)),
                    child: Text(
                      'Welcome to Drivon',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                    ),
                  ),
                ),
                SizedBox(height: 12 * t),
                Opacity(
                  opacity: glow * 0.95,
                  child: Text(
                    'Premium motion. Smarter ownership.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            );
          },
          child: _LogoMark(glowProgress: reveal),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.glowProgress});

  final Animation<double> glowProgress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowProgress,
      builder: (context, _) {
        final g = CurvedAnimation(parent: glowProgress, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)).value;
        return Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withOpacity(0.35 + 0.2 * g),
                blurRadius: 28 + 16 * g,
                spreadRadius: -4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.accentCyan.withOpacity(0.12 + 0.12 * g),
                blurRadius: 40,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Icon(
            Icons.directions_car_rounded,
            size: 52,
            color: Colors.white.withOpacity(0.96),
          ),
        );
      },
    );
  }
}

class _OnboardCopyPage extends StatefulWidget {
  const _OnboardCopyPage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  State<_OnboardCopyPage> createState() => _OnboardCopyPageState();
}

class _OnboardCopyPageState extends State<_OnboardCopyPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final textT = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic)).value;
                final slide = 18 * (1 - textT);
                return Opacity(
                  opacity: textT,
                  child: Transform.translate(
                    offset: Offset(0, slide),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.35,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Expanded(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final cardT = CurvedAnimation(parent: _c, curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic)).value;
                  final scale = 0.94 + 0.06 * CurvedAnimation(parent: _c, curve: const Interval(0.18, 1.0, curve: Curves.easeOutBack)).value;
                  return Opacity(
                    opacity: cardT,
                    child: Transform.translate(
                      offset: Offset(0, 22 * (1 - cardT)),
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.bottomCenter,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: widget.child,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPreviewCard extends StatelessWidget {
  const _DashboardPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.radiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card.withOpacity(0.94),
            AppColors.surface.withOpacity(0.88),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: AppShadows.cardRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniStat('Trips', '12', AppColors.accentCyan)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('Spend', '₹24k', AppColors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Docs', '5', AppColors.blue)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('Health', 'Good', AppColors.accentOrange)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _miniStat(String k, String v, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accent.withOpacity(0.10),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(v, style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ExpenseChartPreview extends StatelessWidget {
  const _ExpenseChartPreview();

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(10, (i) => FlSpot(i.toDouble(), 3 + math.sin(i * 0.65) * 2 + i * 0.15));

    return Container(
      height: 220,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.radiusCard),
        color: AppColors.card.withOpacity(0.92),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: AppShadows.cardSoft,
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.28,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              gradient: AppGradients.chartLine,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.purple.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}

class _InsightsPreviewCard extends StatelessWidget {
  const _InsightsPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.radiusCard),
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.18),
            AppColors.card.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.purple.withOpacity(0.28)),
        boxShadow: AppShadows.cardRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: AppColors.accentCyan.withOpacity(0.95)),
              const SizedBox(width: 10),
              Text(
                'This month',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Fuel spend is trending 8% lower than last month.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan.withOpacity(0.85)),
            ),
          ),
        ],
      ),
    );
  }
}
