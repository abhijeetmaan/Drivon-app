import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/vehicle_scope.dart';
import '../../core/theme/theme.dart';
import '../../features/vehicle/domain/entities/vehicle.dart';
import '../../features/vehicle/presentation/providers/selected_vehicle_provider.dart';
import '../services/device_motion_service.dart';
import 'premium_carousel_physics.dart';

/// Per-page metrics shown on vehicle hero cards.
class VehicleDashboardMetrics {
  const VehicleDashboardMetrics({
    required this.health,
    required this.totalSpent,
    required this.fuelSpent,
    required this.tripsCount,
  });

  final int health;
  final double totalSpent;
  final double fuelSpent;
  final int tripsCount;
}

/// Combined + per-vehicle metrics (same order as [vehicles]).
class VehiclePagerData {
  const VehiclePagerData({
    required this.combined,
    required this.perVehicle,
  });

  final VehicleDashboardMetrics combined;
  final List<VehicleDashboardMetrics> perVehicle;
}

/// Swipe-based vehicle switching with parallax, gradients, dots, and provider sync.
class PremiumVehicleSwitchPager extends ConsumerStatefulWidget {
  const PremiumVehicleSwitchPager({
    super.key,
    required this.vehicles,
    required this.metrics,
    required this.onOpenVehicle,
    required this.onAddVehicle,
  });

  final List<Vehicle> vehicles;
  final VehiclePagerData metrics;
  final void Function(Vehicle vehicle) onOpenVehicle;
  final VoidCallback onAddVehicle;

  @override
  ConsumerState<PremiumVehicleSwitchPager> createState() => _PremiumVehicleSwitchPagerState();
}

class _PremiumVehicleSwitchPagerState extends ConsumerState<PremiumVehicleSwitchPager> {
  late PageController _pageController;
  late DeviceMotionService _motion;
  final ValueNotifier<int> _scrollActivityTick = ValueNotifier(0);
  late final Listenable _carouselListenable;
  var _motionStarted = false;
  int _settledPage = 0;
  var _programmaticPageJump = false;
  bool _scrollListenerAttached = false;

  /// [PageController.page] asserts until scroll metrics exist (`hasContentDimensions`).
  bool _pageMetricsReady() {
    if (!_pageController.hasClients) return false;
    return _pageController.position.hasContentDimensions;
  }

  double _pageForParallax(int index) {
    if (!_pageMetricsReady()) return index.toDouble();
    return _pageController.page ?? index.toDouble();
  }

  /// Background gradients: All, then rotating per vehicle.
  static const List<List<Color>> _gradientPairs = [
    [Color(0xFF6D28D9), Color(0xFF2563EB)],
    [Color(0xFF2563EB), Color(0xFF22D3EE)],
    [Color(0xFFF97316), Color(0xFFEC4899)],
  ];

  int get _itemCount {
    if (widget.vehicles.isEmpty) return 1;
    return widget.vehicles.length + 1;
  }

  int _pageForScope(String scope) {
    if (widget.vehicles.isEmpty) return 0;
    if (scope == kAllVehiclesId) return 0;
    final i = widget.vehicles.indexWhere((v) => v.id == scope);
    return i < 0 ? 0 : i + 1;
  }

  String _scopeForPage(int page) {
    if (widget.vehicles.isEmpty) return kAllVehiclesId;
    if (page <= 0) return kAllVehiclesId;
    return widget.vehicles[page - 1].id;
  }

  List<Color> _colorsForPageIndex(int index) {
    return _gradientPairs[index % _gradientPairs.length];
  }

  @override
  void initState() {
    super.initState();
    final initial = _pageForScope(ref.read(selectedVehicleIdProvider));
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: initial.clamp(0, _itemCount - 1),
    );
    _settledPage = initial;
    _motion = ref.read(deviceMotionServiceProvider);
    _carouselListenable = Listenable.merge([_pageController, _motion, _scrollActivityTick]);
  }

  void _startMotionIfNeeded() {
    if (_motionStarted) return;
    _motionStarted = true;
    _motion.start();
  }

  void _tryAttachCarouselScrollListener() {
    if (_scrollListenerAttached || !_pageController.hasClients) return;
    _scrollListenerAttached = true;
    _pageController.position.isScrollingNotifier.addListener(_onCarouselScrollActivity);
  }

  void _onCarouselScrollActivity() {
    _scrollActivityTick.value++;
  }

  @override
  void didUpdateWidget(covariant PremiumVehicleSwitchPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicles.length != widget.vehicles.length) {
      final scope = ref.read(selectedVehicleIdProvider);
      final target = _pageForScope(scope).clamp(0, _itemCount - 1);
      void jumpWhenReady() {
        if (!mounted) return;
        if (!_pageMetricsReady()) {
          WidgetsBinding.instance.addPostFrameCallback((_) => jumpWhenReady());
          return;
        }
        _pageController.jumpToPage(target);
        setState(() => _settledPage = target);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => jumpWhenReady());
    }
  }

  @override
  void dispose() {
    if (_scrollListenerAttached && _pageController.hasClients) {
      _pageController.position.isScrollingNotifier.removeListener(_onCarouselScrollActivity);
    }
    _scrollActivityTick.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (!_programmaticPageJump) HapticFeedback.lightImpact();
    setState(() => _settledPage = index);
    if (widget.vehicles.isEmpty) return;
    ref.read(selectedVehicleIdProvider.notifier).select(_scopeForPage(index));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedVehicleIdProvider);

    ref.listen<String>(selectedVehicleIdProvider, (previous, next) {
      if (previous == next || widget.vehicles.isEmpty) return;
      final target = _pageForScope(next);

      void animateWhenReady() {
        if (!mounted) return;
        if (!_pageMetricsReady()) {
          WidgetsBinding.instance.addPostFrameCallback((_) => animateWhenReady());
          return;
        }
        final current = _pageController.page?.round() ?? _settledPage;
        if (current == target) return;
        _programmaticPageJump = true;
        _pageController
            .animateToPage(
              target,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutQuart,
            )
            .then((_) {
          if (mounted) _programmaticPageJump = false;
        });
      }

      animateWhenReady();
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification || n is UserScrollNotification) {
          _startMotionIfNeeded();
        }
        return false;
      },
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _carouselListenable,
                  builder: (context, _) {
                    final bgPage = _pageMetricsReady()
                        ? (_pageController.page ?? _settledPage.toDouble())
                        : _settledPage.toDouble();
                    final bgIndexLo = bgPage.floor().clamp(0, _itemCount - 1);
                    final bgIndexHi = bgPage.ceil().clamp(0, _itemCount - 1);
                    final bgT = (bgPage - bgPage.floor()).clamp(0.0, 1.0);
                    final cLo = _colorsForPageIndex(bgIndexLo);
                    final cHi = _colorsForPageIndex(bgIndexHi);
                    final gStart = Color.lerp(cLo[0], cHi[0], bgT)!;
                    final gEnd = Color.lerp(cLo[1], cHi[1], bgT)!;
                    return Transform.translate(
                      offset: Offset(-bgPage * 10, bgPage * 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [gStart, gEnd],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                child: SizedBox(
                  height: 212,
                  child: PageView.builder(
                    controller: _pageController,
                    allowImplicitScrolling: false,
                    itemCount: _itemCount,
                    onPageChanged: _onPageChanged,
                    physics: widget.vehicles.isEmpty
                        ? const NeverScrollableScrollPhysics()
                        : const PremiumCarouselPagePhysics(parent: BouncingScrollPhysics()),
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _carouselListenable,
                          builder: (context, _) {
                            _tryAttachCarouselScrollListener();
                            final page = _pageForParallax(index);
                            final delta = page - index;
                            final ad = delta.abs().clamp(0.0, 1.0);
                            final focus = (1.0 - ad).clamp(0.0, 1.0);
                            final parallax = delta * 11.0;
                            final scale = (0.89 + 0.11 * focus).clamp(0.86, 1.0);
                            final opacity = (0.48 + 0.52 * focus).clamp(0.46, 1.0);
                            final rotY = -delta * 0.12;
                            final rotX = ad * 0.042;
                            final motionBlend = carouselMotionBlend(
                              metricsReady: _pageMetricsReady(),
                              position: _pageController.hasClients ? _pageController.position : null,
                            );
                            final deviceTilt = _motion.sensorsAvailable ? _motion.displayTilt : Offset.zero;
                            final dr = deviceRotationForCard(
                              deviceTilt: deviceTilt,
                              motionBlend: motionBlend,
                              focus: focus,
                              deviceGain: 1.05,
                            );
                            final tilt = Matrix4.identity()
                              ..setEntry(3, 2, 0.0009)
                              ..rotateX(rotX + dr.dx)
                              ..rotateY(rotY + dr.dy);
                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(parallax, delta * -1.8),
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: tilt,
                                  child: Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: _buildPageCard(
                                        context,
                                        index,
                                        delta,
                                        deviceTilt: deviceTilt,
                                        motionBlend: motionBlend,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (widget.vehicles.isNotEmpty)
          _PageDots(count: _itemCount, current: _settledPage.clamp(0, _itemCount - 1)),
      ],
    ),
    );
  }

  Widget _buildPageCard(
    BuildContext context,
    int index,
    double scrollDelta, {
    Offset deviceTilt = Offset.zero,
    double motionBlend = 1,
  }) {
    if (widget.vehicles.isEmpty) {
      return _AddVehicleHeroCard(
        onTap: widget.onAddVehicle,
        scrollDelta: scrollDelta,
        deviceTilt: deviceTilt,
        motionBlend: motionBlend,
      );
    }

    if (index == 0) {
      final m = widget.metrics.combined;
      return _VehicleHeroCard(
        title: 'All Vehicles',
        subtitle: 'Combined · ${widget.vehicles.length} in garage',
        metrics: m,
        icon: Icons.layers_rounded,
        onTap: null,
        scrollDelta: scrollDelta,
        deviceTilt: deviceTilt,
        motionBlend: motionBlend,
      );
    }

    final v = widget.vehicles[index - 1];
    final m = widget.metrics.perVehicle[index - 1];
    return Hero(
      tag: 'vehicle_${v.id}',
      child: Material(
        color: Colors.transparent,
        child: _VehicleHeroCard(
          title: v.name,
          subtitle: '${v.model} · ${v.fuelType}',
          metrics: m,
          icon: Icons.directions_car_filled_rounded,
          onTap: () => widget.onOpenVehicle(v),
          scrollDelta: scrollDelta,
          deviceTilt: deviceTilt,
          motionBlend: motionBlend,
        ),
      ),
    );
  }
}

class _VehicleHeroCard extends StatelessWidget {
  const _VehicleHeroCard({
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.icon,
    this.onTap,
    this.scrollDelta = 0,
    this.deviceTilt = Offset.zero,
    this.motionBlend = 1,
  });

  final String title;
  final String subtitle;
  final VehicleDashboardMetrics metrics;
  final IconData icon;
  final VoidCallback? onTap;
  final double scrollDelta;
  final Offset deviceTilt;
  final double motionBlend;

  static final _fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final d = scrollDelta.clamp(-1.25, 1.25);
    final focus = (1.0 - d.abs().clamp(0.0, 1.0)).clamp(0.0, 1.0);
    final mb = motionBlend.clamp(0.0, 1.0);
    final gloss = glossAlignmentsForTilt(
      scrollDelta: d,
      deviceTilt: deviceTilt,
      motionBlend: mb,
      focus: focus,
    );
    final watermarkTilt = Matrix4.identity()
      ..setEntry(3, 2, 0.00115)
      ..rotateY(-d * 0.095 - deviceTilt.dx * 0.048 * mb)
      ..rotateX(d.abs() * 0.032 - deviceTilt.dy * 0.038 * mb);
    final badgeTilt = Matrix4.identity()
      ..rotateY(-d * 0.052 + deviceTilt.dx * 0.032 * mb)
      ..rotateZ(-d * 0.014 - deviceTilt.dy * 0.012 * mb);
    final shadows = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withOpacity(0.26 + 0.14 * focus),
        blurRadius: 10 + 20 * focus,
        spreadRadius: -3,
        offset: Offset(d * 14, 7 + 9 * focus),
      ),
      if (focus > 0.45)
        BoxShadow(
          color: AppColors.accentCyan.withOpacity(0.11 + 0.12 * focus),
          blurRadius: 22 + 8 * focus,
          spreadRadius: -6,
          offset: Offset(-d * 6, 2),
        ),
    ];

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.11 + 0.02 * focus),
        border: Border.all(
          color: Color.lerp(
                Colors.white.withOpacity(0.18),
                AppColors.accentCyan.withOpacity(0.35),
                (focus - 0.4).clamp(0.0, 1.0) * 0.85,
              ) ??
              Colors.white.withOpacity(0.22),
          width: focus > 0.72 ? 1.35 : 1,
        ),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            if (focus > 0.35)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.07 * focus),
                        Colors.transparent,
                        Colors.black.withOpacity(0.04 * (1 - focus)),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: Offset(
                    deviceTilt.dx * 28 * mb * focus,
                    deviceTilt.dy * 22 * mb * focus,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: gloss.begin,
                        end: gloss.end,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.045 * focus * (0.5 + 0.5 * mb)),
                          Colors.white.withOpacity(0.1 * focus),
                          AppColors.accentCyan.withOpacity(0.07 * focus * mb),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.12, 0.38, 0.5, 0.62, 0.9],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Transform(
                alignment: Alignment.center,
                transform: watermarkTilt,
                child: Icon(icon, size: 120, color: Colors.white.withOpacity(0.07 + 0.03 * focus)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Transform(
                        alignment: Alignment.center,
                        transform: badgeTilt,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16 + 0.06 * focus),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: focus > 0.55
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(icon, color: Colors.white, size: 26),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.88),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat(
                          context,
                          'Health',
                          '${metrics.health}',
                          Icons.favorite_outline,
                        ),
                      ),
                      Expanded(
                        child: _miniStat(
                          context,
                          'Spent',
                          _fmt.format(metrics.totalSpent),
                          Icons.payments_outlined,
                        ),
                      ),
                      Expanded(
                        child: _miniStat(
                          context,
                          'Fuel',
                          _fmt.format(metrics.fuelSpent),
                          Icons.local_gas_station_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: card,
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white.withOpacity(0.75)),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _AddVehicleHeroCard extends StatelessWidget {
  const _AddVehicleHeroCard({
    required this.onTap,
    this.scrollDelta = 0,
    this.deviceTilt = Offset.zero,
    this.motionBlend = 1,
  });

  final VoidCallback onTap;
  final double scrollDelta;
  final Offset deviceTilt;
  final double motionBlend;

  @override
  Widget build(BuildContext context) {
    final d = scrollDelta.clamp(-1.25, 1.25);
    final focus = (1.0 - d.abs().clamp(0.0, 1.0)).clamp(0.0, 1.0);
    final mb = motionBlend.clamp(0.0, 1.0);
    final gloss = glossAlignmentsForTilt(scrollDelta: d, deviceTilt: deviceTilt, motionBlend: mb, focus: focus);
    final iconTilt = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(-d * 0.09 + deviceTilt.dx * 0.05 * mb)
      ..rotateX(d.abs() * 0.025 - deviceTilt.dy * 0.04 * mb);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22 + 0.1 * focus),
                blurRadius: 14 + 12 * focus,
                offset: Offset(d * 10, 8 + 4 * focus),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13 + 0.02 * focus),
                    border: Border.all(color: Colors.white.withOpacity(0.26 + 0.06 * focus)),
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Your garage is empty',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a vehicle to unlock swipe switching, stats, and voice.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Transform(
                        alignment: Alignment.center,
                        transform: iconTilt,
                        child: Icon(Icons.add_circle_outline, color: Colors.white.withOpacity(0.92 + 0.03 * focus), size: 44),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(deviceTilt.dx * 24 * mb, deviceTilt.dy * 18 * mb),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: gloss.begin,
                            end: gloss.end,
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.06 * focus * mb),
                              Colors.white.withOpacity(0.0),
                            ],
                            stops: const [0.35, 0.52, 0.72],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 7,
                  width: i == current ? 22 : 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: i == current ? AppColors.accentCyan : AppColors.textSecondary.withOpacity(0.35),
                    boxShadow: i == current
                        ? [
                            BoxShadow(
                              color: AppColors.accentCyan.withOpacity(0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
