import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/vehicle_scope.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../shared/widgets/drivon_logo.dart';
import '../../../../shared/widgets/animated_entry.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/expandable_fab_widget.dart';
import '../../../../shared/widgets/gradient_circular_progress.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/dialogs/delete_confirmation.dart' show deleteSwipeBackground, showItemDeletedSnackbar, showPremiumDeleteDialog;
import '../../../../shared/selection/list_selection_controller.dart';
import '../../../../shared/widgets/selectable_swipe_tile.dart';
import '../../../../shared/widgets/staggered_list_entry.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/immersive_motion_layer.dart';
import '../../../../shared/widgets/premium_vehicle_switch_pager.dart';
import '../../../../shared/widgets/vehicle_scope_bar.dart';
import '../../../documents/presentation/screens/documents_screen.dart';
import '../../../documents/presentation/screens/add_document_screen.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../expenses/presentation/screens/add_expense_screen.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../trips/presentation/screens/trips_screen.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/selected_vehicle_provider.dart';
import '../providers/vehicle_filter_providers.dart';
import '../providers/vehicle_providers.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final ListSelectionController _homeSelection = ListSelectionController();

  @override
  void dispose() {
    _homeSelection.dispose();
    super.dispose();
  }

  Future<void> _bulkHomeDelete() async {
    final ids = _homeSelection.selectedIds.toList();
    if (ids.isEmpty) return;
    final expenses = ref.read(expensesProvider).value ?? const <Expense>[];
    final n = ids.length;

    String title;
    String successMessage;
    if (n == 1) {
      final k = ids.first;
      if (k.startsWith('hexp:')) {
        final id = k.substring(5);
        final exp = expenses.firstWhere((e) => e.id == id);
        title = 'Delete ${exp.type} entry?';
        successMessage = '${exp.type} entry deleted';
      } else if (k.startsWith('htrip:')) {
        title = 'Delete Trip?';
        successMessage = 'Trip deleted';
      } else {
        title = 'Delete Vehicle?';
        successMessage = 'Vehicle deleted';
      }
    } else {
      title = 'Delete $n items?';
      successMessage = '$n items deleted';
    }

    final ok = await showPremiumDeleteDialog(
      context,
      title: title,
      onConfirm: () async {
        for (final k in ids) {
          if (k.startsWith('hexp:')) {
            await ref.read(expenseActionsProvider).deleteExpense(k.substring(5));
          } else if (k.startsWith('htrip:')) {
            await ref.read(tripActionsProvider).deleteTrip(k.substring(6));
          } else if (k.startsWith('hveh:')) {
            await ref.read(vehicleActionsProvider).deleteVehicle(k.substring(5));
          }
        }
      },
      successMessage: successMessage,
    );
    if (ok && mounted) _homeSelection.clear();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final tripsAsync = ref.watch(tripsProvider);

    return ListenableBuilder(
      listenable: _homeSelection,
      builder: (context, _) {
        return vehiclesAsync.when(
      loading: () => AppScaffold(body: SkeletonLoader.screenList()),
      error: (e, _) => AppScaffold(
        body: Center(
          child: Text('Failed to load vehicles: $e', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
      data: (vehicles) {
        final scope = ref.watch(selectedVehicleIdProvider);
        Vehicle? selectedVehicle;
        if (vehicles.isNotEmpty && scope != kAllVehiclesId) {
          for (final v in vehicles) {
            if (v.id == scope) {
              selectedVehicle = v;
              break;
            }
          }
        }

        final scopeExpenses = ref.watch(filteredExpensesProvider);
        final scopeTrips = ref.watch(filteredTripsProvider);

        final totalSpent = scopeExpenses.fold<double>(0, (s, e) => s + e.amount);
        final fuelSpent = scopeExpenses
            .where((e) => e.type.toLowerCase() == 'fuel')
            .fold<double>(0, (s, e) => s + e.amount);

        final recentExpenses = scopeExpenses.take(3).toList();
        final recentTrips = scopeTrips.take(2).toList();

        final allExpenses = expensesAsync.value ?? const <Expense>[];
        final allTrips = tripsAsync.value ?? const <Trip>[];
        final pagerData = _buildVehiclePagerData(vehicles, allExpenses, allTrips);

        final health = _healthScoreForScope(
          scope: scope,
          vehicles: vehicles,
          expenses: expensesAsync.value ?? const <Expense>[],
          trips: tripsAsync.value ?? const <Trip>[],
        );

        final healthCaption = vehicles.isEmpty
            ? 'Add a vehicle to track maintenance'
            : scope == kAllVehiclesId
                ? 'Average health across ${vehicles.length} vehicle${vehicles.length == 1 ? '' : 's'}'
                : 'Estimated next service window · ~45 days';

        return AppScaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _homeSelection.isActive
                      ? Material(
                          key: const ValueKey('home_sel'),
                          elevation: 3,
                          shadowColor: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.card.withOpacity(0.96),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Cancel',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _homeSelection.clear();
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    '${_homeSelection.count} selected',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Delete',
                                  onPressed: _homeSelection.count == 0 ? null : _bulkHomeDelete,
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(key: ValueKey('home_nosel'), height: 0),
                ),
                if (_homeSelection.isActive) const SizedBox(height: 12),
                AnimatedEntry(
                  beginOffset: const Offset(0, -0.04),
                  child: _HeaderGreeting(
                    name: 'Abhijeet',
                    subtitle: vehicles.isEmpty
                        ? 'Add a vehicle to get started'
                        : scope == kAllVehiclesId
                            ? 'All vehicles · combined metrics'
                            : selectedVehicle != null
                                ? '${selectedVehicle.name} · ${selectedVehicle.fuelType}'
                                : 'Pick a vehicle to focus this dashboard',
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                AnimatedEntry(
                  delay: const Duration(milliseconds: 28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                    child: PremiumVehicleSwitchPager(
                      vehicles: vehicles,
                      metrics: pagerData,
                      onOpenVehicle: (v) => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: v)),
                      ),
                      onAddVehicle: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                AnimatedEntry(
                  delay: const Duration(milliseconds: 36),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                    child: VehicleScopeBar(),
                  ),
                ),
                const SizedBox(height: AppLayout.sectionGap),
                AnimatedEntry(
                  delay: const Duration(milliseconds: 72),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      key: ValueKey<String>('home_dash_$scope'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ImmersiveMotionLayer(
                          gyroIntensity: 0.032,
                          glossStrength: 0.36,
                          child: _VehicleHealthHero(
                            score: health,
                            caption: healthCaption,
                          ),
                        ),
                        const SizedBox(height: AppLayout.sectionGap),
                        _AnimatedStatsRow(
                          animationKey: scope,
                          totalSpent: totalSpent,
                          fuelSpent: fuelSpent,
                          tripsCount: scopeTrips.length,
                        ),
                        const SizedBox(height: AppLayout.sectionGap),
                        _ExpenseTrendCard(series: _monthlySeries(scopeExpenses)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppLayout.sectionGap),
                AnimatedEntry(
                  delay: const Duration(milliseconds: 140),
                  child: ImmersiveMotionLayer(
                    gyroIntensity: 0.03,
                    glossStrength: 0.35,
                    child: CustomCard(
                      prominent: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.purple.withOpacity(0.35),
                                  AppColors.blue.withOpacity(0.25),
                                ],
                              ),
                            ),
                            child: const Icon(Icons.description_outlined, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Documents',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Insurance, PUC, permits',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withOpacity(0.8)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (recentExpenses.isNotEmpty || recentTrips.isNotEmpty) ...[
                  const SizedBox(height: AppLayout.sectionGap),
                  const SectionHeader(title: 'Recent'),
                  if (recentExpenses.isNotEmpty) ...[
                    ...recentExpenses.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppLayout.elementGap + 2),
                        child: StaggeredListEntry(
                          index: e.key,
                          child: SelectableSwipeTile(
                            itemId: 'hexp:${e.value.id}',
                            selection: _homeSelection,
                            dismissKey: ValueKey('home_exp_${e.value.id}'),
                            swipeBackground: deleteSwipeBackground(),
                            confirmSwipeDelete: () async => await showPremiumDeleteDialog(
                                  context,
                                  title: 'Delete ${e.value.type} entry?',
                                  showSuccessSnackBar: false,
                                ),
                            onSwipeConfirmedDelete: () async {
                              await ref.read(expenseActionsProvider).deleteExpense(e.value.id);
                              if (context.mounted) {
                                showItemDeletedSnackbar(context, '${e.value.type} entry deleted');
                              }
                            },
                            onTapOpen: null,
                            child: _activityCard(
                              context,
                              icon: _expenseIcon(e.value.type),
                              accent: _expenseAccent(e.value.type),
                              title: e.value.type,
                              subtitle: e.value.note.isEmpty
                                  ? DateFormat('MMM d').format(e.value.date)
                                  : e.value.note,
                              amount: _currency.format(e.value.amount),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (recentTrips.isNotEmpty) ...[
                    ...recentTrips.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppLayout.elementGap + 2),
                        child: StaggeredListEntry(
                          index: e.key + recentExpenses.length,
                          child: SelectableSwipeTile(
                            itemId: 'htrip:${e.value.id}',
                            selection: _homeSelection,
                            dismissKey: ValueKey('home_trip_${e.value.id}'),
                            swipeBackground: deleteSwipeBackground(),
                            confirmSwipeDelete: () async => await showPremiumDeleteDialog(
                                  context,
                                  title: 'Delete Trip?',
                                  showSuccessSnackBar: false,
                                ),
                            onSwipeConfirmedDelete: () async {
                              await ref.read(tripActionsProvider).deleteTrip(e.value.id);
                              if (context.mounted) showItemDeletedSnackbar(context, 'Trip deleted');
                            },
                            onTapOpen: null,
                            child: _activityCard(
                              context,
                              icon: Icons.route_outlined,
                              accent: AppColors.accentCyan,
                              title: e.value.name,
                              subtitle: '${e.value.members.length} members · ${e.value.expenses.length} expenses',
                              amount: DateFormat('MMM d').format(e.value.createdAt),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppLayout.sectionGap),
                SectionHeader(
                  title: 'Garage',
                  trailing: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
                      );
                    },
                    child: const Text('Add'),
                  ),
                ),
                if (vehicles.isEmpty)
                  EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: 'No vehicles yet',
                    message: 'Create your first vehicle to unlock tracking across the app.',
                    actionLabel: 'Add vehicle',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
                    ),
                  )
                else
                  ...vehicles.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppLayout.elementGap + 2),
                      child: StaggeredListEntry(
                        index: e.key,
                        child: SelectableSwipeTile(
                          itemId: 'hveh:${e.value.id}',
                          selection: _homeSelection,
                          dismissKey: ValueKey('home_veh_${e.value.id}'),
                          swipeBackground: deleteSwipeBackground(),
                          confirmSwipeDelete: () async => await showPremiumDeleteDialog(
                                context,
                                title: 'Delete Vehicle?',
                                showSuccessSnackBar: false,
                              ),
                          onSwipeConfirmedDelete: () async {
                            await ref.read(vehicleActionsProvider).deleteVehicle(e.value.id);
                            if (context.mounted) showItemDeletedSnackbar(context, 'Vehicle deleted');
                          },
                          onTapOpen: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: e.value)),
                            );
                          },
                          child: CustomCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.directions_car_filled_outlined, color: Colors.white),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.value.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${e.value.model} · ${e.value.fuelType}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    DateFormat('MMM d').format(e.value.createdAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: _homeSelection.isActive
              ? null
              : ExpandableFabWidget(
                  actions: [
                    ExpandableFabAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Add Expense',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(
                            initialType: 'Service',
                            preferredVehicleId: ref.read(selectedVehicleIdProvider),
                          ),
                        ),
                      ),
                      accent: AppColors.accentOrange,
                    ),
                    ExpandableFabAction(
                      icon: Icons.route_outlined,
                      label: 'Add Trip',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TripsScreen()),
                      ),
                      accent: AppColors.accentCyan,
                    ),
                    ExpandableFabAction(
                      icon: Icons.upload_file_rounded,
                      label: 'Upload Doc',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddDocumentScreen()),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
      },
    );
  }
}

Widget _activityCard(
  BuildContext context, {
  required IconData icon,
  required Color accent,
  required String title,
  required String subtitle,
  required String amount,
}) {
  return CustomCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: SizedBox(
      height: 56,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withOpacity(0.16),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              amount,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeaderGreeting extends StatelessWidget {
  final String name;
  final String subtitle;

  const _HeaderGreeting({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DrivonLogo(size: 22, glow: true, pulse: 0.35),
                  const SizedBox(width: 8),
                  Text(
                    'Drivon',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Hey, $name',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => HapticFeedback.lightImpact(),
          icon: const Icon(Icons.notifications_none_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.textPrimary,
          ),
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: AppShadows.cardSoft,
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surface,
            child: Icon(Icons.person_rounded, color: AppColors.textSecondary.withOpacity(0.9)),
          ),
        ),
      ],
    );
  }
}

class _VehicleHealthHero extends StatelessWidget {
  final int score;
  final String caption;

  const _VehicleHealthHero({required this.score, required this.caption});

  @override
  Widget build(BuildContext context) {
    final p = (score / 100).clamp(0.0, 1.0);
    return CustomCard(
      prominent: true,
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: p),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => GradientCircularProgress(
              size: 92,
              strokeWidth: 5.5,
              progress: v,
              child: Text(
                '$score',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health score',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(caption, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatsRow extends StatelessWidget {
  const _AnimatedStatsRow({
    required this.animationKey,
    required this.totalSpent,
    required this.fuelSpent,
    required this.tripsCount,
  });

  final String animationKey;
  final double totalSpent;
  final double fuelSpent;
  final int tripsCount;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('${animationKey}_stats'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: 0.82 + 0.18 * t,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: child,
          ),
        );
      },
      child: ImmersiveMotionLayer(
        gyroIntensity: 0.028,
        glossStrength: 0.3,
        child: _StatsRow(
          totalSpent: totalSpent,
          fuelSpent: fuelSpent,
          tripsCount: tripsCount,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final double totalSpent;
  final double fuelSpent;
  final int tripsCount;

  const _StatsRow({
    required this.totalSpent,
    required this.fuelSpent,
    required this.tripsCount,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.payments_outlined,
              label: 'Spent',
              value: fmt.format(totalSpent),
              accent: AppColors.accentCyan,
            ),
          ),
          const SizedBox(width: AppLayout.elementGap),
          Expanded(
            child: StatCard(
              icon: Icons.local_gas_station_outlined,
              label: 'Fuel',
              value: fmt.format(fuelSpent),
              accent: AppColors.accentOrange,
            ),
          ),
          const SizedBox(width: AppLayout.elementGap),
          Expanded(
            child: StatCard(
              icon: Icons.route_outlined,
              label: 'Trips',
              value: '$tripsCount',
              accent: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTrendCard extends StatefulWidget {
  final List<double> series;
  const _ExpenseTrendCard({required this.series});

  @override
  State<_ExpenseTrendCard> createState() => _ExpenseTrendCardState();
}

class _ExpenseTrendCardState extends State<_ExpenseTrendCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
      child: ImmersiveMotionLayer(
        gyroIntensity: 0.026,
        glossStrength: 0.34,
        child: CustomCard(
          prominent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending trend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppLayout.sectionGap),
              SizedBox(
                height: 132,
                child: ClipRect(
                  child: _MiniLineChart(series: widget.series),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _vehicleHealthScore({
  required double totalSpent,
  required double fuelSpent,
  required int tripsCount,
  required bool hasVehicle,
}) {
  if (!hasVehicle) return 0;
  var score = 92;
  score -= (totalSpent / 8000).floor().clamp(0, 35);
  score -= (fuelSpent / 5000).floor().clamp(0, 10);
  score += (tripsCount / 3).floor().clamp(0, 8);
  return score.clamp(35, 100);
}

int _healthScoreForScope({
  required String scope,
  required List<Vehicle> vehicles,
  required List<Expense> expenses,
  required List<Trip> trips,
}) {
  if (vehicles.isEmpty) return 0;
  if (scope == kAllVehiclesId) {
    var sum = 0;
    for (final v in vehicles) {
      final ve = expenses.where((e) => e.vehicleId == v.id).toList();
      final vt = trips.where((t) => t.vehicleId == v.id).toList();
      sum += _vehicleHealthScore(
        totalSpent: ve.fold<double>(0, (s, e) => s + e.amount),
        fuelSpent: ve.where((e) => e.type.toLowerCase() == 'fuel').fold<double>(0, (s, e) => s + e.amount),
        tripsCount: vt.length,
        hasVehicle: true,
      );
    }
    return (sum / vehicles.length).round();
  }
  final ve = expenses.where((e) => e.vehicleId == scope).toList();
  final vt = trips.where((t) => t.vehicleId == scope).toList();
  return _vehicleHealthScore(
    totalSpent: ve.fold<double>(0, (s, e) => s + e.amount),
    fuelSpent: ve.where((e) => e.type.toLowerCase() == 'fuel').fold<double>(0, (s, e) => s + e.amount),
    tripsCount: vt.length,
    hasVehicle: vehicles.any((v) => v.id == scope),
  );
}

VehiclePagerData _buildVehiclePagerData(
  List<Vehicle> vehicles,
  List<Expense> allExpenses,
  List<Trip> allTrips,
) {
  if (vehicles.isEmpty) {
    return const VehiclePagerData(
      combined: VehicleDashboardMetrics(
        health: 0,
        totalSpent: 0,
        fuelSpent: 0,
        tripsCount: 0,
      ),
      perVehicle: [],
    );
  }

  final combinedHealth = _healthScoreForScope(
    scope: kAllVehiclesId,
    vehicles: vehicles,
    expenses: allExpenses,
    trips: allTrips,
  );

  final combined = VehicleDashboardMetrics(
    health: combinedHealth,
    totalSpent: allExpenses.fold<double>(0, (s, e) => s + e.amount),
    fuelSpent: allExpenses
        .where((e) => e.type.toLowerCase() == 'fuel')
        .fold<double>(0, (s, e) => s + e.amount),
    tripsCount: allTrips.length,
  );

  final perVehicle = vehicles.map((v) {
    final ve = allExpenses.where((e) => e.vehicleId == v.id).toList();
    final vt = allTrips.where((t) => t.vehicleId == v.id).toList();
    final h = _vehicleHealthScore(
      totalSpent: ve.fold<double>(0, (s, e) => s + e.amount),
      fuelSpent: ve.where((e) => e.type.toLowerCase() == 'fuel').fold<double>(0, (s, e) => s + e.amount),
      tripsCount: vt.length,
      hasVehicle: true,
    );
    return VehicleDashboardMetrics(
      health: h,
      totalSpent: ve.fold<double>(0, (s, e) => s + e.amount),
      fuelSpent: ve.where((e) => e.type.toLowerCase() == 'fuel').fold<double>(0, (s, e) => s + e.amount),
      tripsCount: vt.length,
    );
  }).toList();

  return VehiclePagerData(combined: combined, perVehicle: perVehicle);
}

class _MiniLineChart extends StatelessWidget {
  final List<double> series;
  const _MiniLineChart({required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Add expenses to see your curve',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final spots = <FlSpot>[
      for (int i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i]),
    ];
    final maxY = series.reduce((a, b) => a > b ? a : b);
    final safeMax = maxY == 0 ? 1.0 : maxY * 1.15;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: safeMax,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeMax > 0 ? safeMax / 3 : 1,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.white.withOpacity(0.055),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                final now = DateTime.now();
                final d = DateTime(now.year, now.month - (series.length - 1 - i));
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('MMM').format(d),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary.withOpacity(0.85),
                        ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.42,
            color: null,
            gradient: const LinearGradient(
              colors: [AppColors.purple, AppColors.blue],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: 3.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, p, bar, i) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.blue,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.purple.withOpacity(0.32),
                  AppColors.blue.withOpacity(0.04),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }
}

Color _expenseAccent(String type) {
  switch (type.toLowerCase()) {
    case 'fuel':
      return AppColors.accentOrange;
    case 'service':
      return AppColors.accentCyan;
    case 'insurance':
      return AppColors.blue;
    default:
      return AppColors.purple;
  }
}

IconData _expenseIcon(String type) {
  switch (type.toLowerCase()) {
    case 'fuel':
      return Icons.local_gas_station_outlined;
    case 'service':
      return Icons.build_circle_outlined;
    case 'insurance':
      return Icons.verified_user_outlined;
    default:
      return Icons.payments_outlined;
  }
}

List<double> _monthlySeries(List<Expense> expenses) {
  if (expenses.isEmpty) return const [];
  final now = DateTime.now();
  final months = <DateTime>[
    for (int i = 5; i >= 0; i--) DateTime(now.year, now.month - i),
  ];
  final totals = <DateTime, double>{for (final m in months) m: 0.0};
  for (final e in expenses) {
    final key = DateTime(e.date.year, e.date.month);
    if (totals.containsKey(key)) totals[key] = (totals[key] ?? 0) + e.amount;
  }
  return [for (final m in months) totals[m] ?? 0];
}
