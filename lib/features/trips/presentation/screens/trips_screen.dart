import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/vehicle_scope.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../shared/dialogs/delete_confirmation.dart'
    show
        deleteSwipeBackground,
        showItemDeletedSnackbar,
        showPremiumDeleteDialog;
import '../../../../shared/selection/list_selection_controller.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/gradient_fab.dart';
import '../../../../shared/widgets/selectable_swipe_tile.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/staggered_list_entry.dart';
import '../../../../shared/widgets/vehicle_scope_bar.dart';
import '../../../vehicle/presentation/providers/selected_vehicle_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_filter_providers.dart';
import '../../../vehicle/presentation/providers/vehicle_providers.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_providers.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  final ListSelectionController _selection = ListSelectionController();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  Future<void> _bulkDelete(List<Trip> trips) async {
    final ids = _selection.selectedIds.toList();
    if (ids.isEmpty) return;
    final n = ids.length;
    final ok = await showPremiumDeleteDialog(
      context,
      title: n == 1 ? 'Delete Trip?' : 'Delete $n items?',
      onConfirm: () async {
        for (final id in ids) {
          await ref.read(tripActionsProvider).deleteTrip(id);
        }
      },
      successMessage: n == 1 ? 'Trip deleted' : '$n items deleted',
    );
    if (ok && mounted) _selection.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);
    final scope = ref.watch(selectedVehicleIdProvider);

    return ListenableBuilder(
      listenable: _selection,
      builder: (context, _) {
        return AppScaffold(
          appBar: _selection.isActive
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _selection.clear();
                    },
                  ),
                  title: Text(
                    '${_selection.count} selected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete selected',
                      onPressed: _selection.count == 0
                          ? null
                          : () {
                              final list = ref.read(filteredTripsProvider);
                              if (list.isEmpty) return;
                              _bulkDelete(list);
                            },
                    ),
                  ],
                )
              : AppBar(
                  title: const Text('Trips'),
                  actions: [
                    IconButton(
                      onPressed: () => _showCreateTrip(context, ref),
                      icon: const Icon(Icons.add),
                      tooltip: 'Create trip',
                    ),
                  ],
                ),
          body: tripsAsync.when(
            loading: () => SingleChildScrollView(
              padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(
                      height: 72,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  const SizedBox(height: AppSpacing.s16),
                  for (var i = 0; i < 6; i++) ...[
                    const Skeleton(
                        height: 76,
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            error: (e, _) => Center(child: Text('Failed to load trips: $e')),
            data: (_) {
              final trips = ref.watch(filteredTripsProvider);
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.only(top: AppSpacing.s16, bottom: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                      child: VehicleScopeBar(compact: true),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16),
                      child: CustomCard(
                        prominent: true,
                        child: Text(
                          'Split expenses fairly — long-press to select, swipe right to delete.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    if (trips.isEmpty)
                      EmptyState(
                        icon: Icons.route_outlined,
                        title: 'No trips here',
                        message: scope == kAllVehiclesId
                            ? 'Create your first ride-split trip and start tracking who owes whom.'
                            : 'No trips for this vehicle yet. Create one or switch scope to All.',
                        actionLabel: 'Create trip',
                        onAction: () => _showCreateTrip(context, ref),
                      )
                    else
                      ...trips.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.s16,
                                right: AppSpacing.s16,
                                bottom: AppSpacing.s8 + 2,
                              ),
                              child: StaggeredListEntry(
                                index: e.key,
                                child: SelectableSwipeTile(
                                  itemId: e.value.id,
                                  selection: _selection,
                                  dismissKey: ValueKey('trip_${e.value.id}'),
                                  swipeBackground: deleteSwipeBackground(),
                                  confirmSwipeDelete: () async =>
                                      await showPremiumDeleteDialog(
                                    context,
                                    title: 'Delete Trip?',
                                    showSuccessSnackBar: false,
                                  ),
                                  onSwipeConfirmedDelete: () async {
                                    await ref
                                        .read(tripActionsProvider)
                                        .deleteTrip(e.value.id);
                                    if (context.mounted)
                                      showItemDeletedSnackbar(
                                          context, 'Trip deleted');
                                  },
                                  onTapOpen: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              TripDetailScreen(trip: e.value)),
                                    );
                                  },
                                  child: CustomCard(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: SizedBox(
                                      height: 56,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              color: AppColors.accentCyan
                                                  .withOpacity(0.16),
                                            ),
                                            child: const Icon(
                                                Icons.route_outlined,
                                                color: AppColors.accentCyan,
                                                size: 22),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  e.value.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${e.value.members.length} members · ${e.value.expenses.length} expenses',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              DateFormat('MMM d')
                                                  .format(e.value.createdAt),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium,
                                            ),
                                          ),
                                          Icon(Icons.chevron_right_rounded,
                                              color: AppColors.textSecondary
                                                  .withOpacity(0.8)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: _selection.isActive
              ? null
              : GradientExtendedFab(
                  onPressed: () => _showCreateTrip(context, ref),
                  label: 'Create',
                  tooltip: 'Create trip',
                ),
        );
      },
    );
  }
}

Future<void> _showCreateTrip(BuildContext context, WidgetRef ref) async {
  final vehicles = ref.read(vehiclesProvider).valueOrNull ?? [];
  if (vehicles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add a vehicle before creating a trip.')),
    );
    return;
  }

  final controller = TextEditingController();
  var vehicleId = defaultVehicleIdForNewData(ref) ?? vehicles.first.id;
  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final screenWidth = MediaQuery.of(ctx).size.width;
          final dialogWidth = screenWidth * 0.9;
          final maxWidth = 500.0;
          final constrainedWidth =
              dialogWidth > maxWidth ? maxWidth : dialogWidth;

          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        'Create trip',
                        style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Vehicle Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Vehicle',
                            style:
                                Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: vehicleId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              for (final v in vehicles)
                                DropdownMenuItem(
                                  value: v.id,
                                  child: Flexible(
                                    child: Text(
                                      '${v.name} · ${v.model}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: saving
                                ? null
                                : (v) =>
                                    setState(() => vehicleId = v ?? vehicleId),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Trip Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Trip name',
                            style:
                                Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller,
                            enabled: !saving,
                            decoration: InputDecoration(
                              hintText: 'e.g. Goa ride',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: TextButton(
                              onPressed:
                                  saving ? null : () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: FilledButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final name = controller.text.trim();
                                      if (name.isEmpty) return;
                                      setState(() => saving = true);
                                      try {
                                        await ref
                                            .read(tripActionsProvider)
                                            .createTrip(
                                                name: name,
                                                vehicleId: vehicleId);
                                        if (ctx.mounted)
                                          Navigator.of(ctx).pop();
                                      } finally {
                                        if (ctx.mounted)
                                          setState(() => saving = false);
                                      }
                                    },
                              child: saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Create'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
