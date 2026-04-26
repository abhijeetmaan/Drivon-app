import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/vehicle_scope.dart';
import '../../core/theme/theme.dart';
import '../../features/vehicle/domain/entities/vehicle.dart';
import '../../features/vehicle/presentation/providers/selected_vehicle_provider.dart';
import '../../features/vehicle/presentation/providers/vehicle_providers.dart';

/// Top scope control: "All vehicles" plus one chip per garage entry.
class VehicleScopeBar extends ConsumerWidget {
  const VehicleScopeBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final selected = ref.watch(selectedVehicleIdProvider);

    return vehiclesAsync.when(
      loading: () => const SizedBox(height: 44, child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))),
      error: (e, _) => Text('Vehicles: $e', style: Theme.of(context).textTheme.bodySmall),
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return _EmptyGarageHint(compact: compact);
        }

        var effective = selected;
        if (effective != kAllVehiclesId && !vehicles.any((v) => v.id == effective)) {
          effective = kAllVehiclesId;
        }

        final chips = <Widget>[
          _ScopeChip(
            label: 'All',
            subtitle: 'Combined',
            compact: compact,
            selected: effective == kAllVehiclesId,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(selectedVehicleIdProvider.notifier).select(kAllVehiclesId);
            },
          ),
          ...vehicles.map(
            (Vehicle v) => _ScopeChip(
              label: v.name,
              subtitle: v.model,
              compact: compact,
              selected: effective == v.id,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(selectedVehicleIdProvider.notifier).select(v.id);
              },
            ),
          ),
        ];

        return SizedBox(
          height: compact ? 48 : 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            clipBehavior: Clip.none,
            itemCount: chips.length,
            separatorBuilder: (_, __) => SizedBox(width: compact ? 8 : 10),
            itemBuilder: (_, i) => chips[i],
          ),
        );
      },
    );
  }
}

class _EmptyGarageHint extends StatelessWidget {
  const _EmptyGarageHint({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.garage_outlined, color: Theme.of(context).colorScheme.primary, size: compact ? 20 : 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add a vehicle to assign expenses, trips, and documents.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.subtitle,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxW = compact ? 132.0 : 168.0;
    // Fixed width so horizontal ListView can measure items and scroll instead of overflowing.
    return SizedBox(
      width: maxW,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            constraints: BoxConstraints(minHeight: compact ? 36 : 50),
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14, vertical: compact ? 6 : 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? scheme.primary : Colors.white.withOpacity(0.12),
              width: selected ? 1.5 : 1,
            ),
            color: selected ? scheme.primary.withOpacity(0.16) : AppColors.card.withOpacity(0.55),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: compact
              ? Text(
                  '$label · $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: selected ? scheme.primary : AppColors.textPrimary,
                      ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: selected ? scheme.primary : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
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
