import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/vehicle_scope.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/app_spacing.dart';
import '../../features/vehicle/domain/entities/vehicle.dart';
import '../../features/vehicle/presentation/providers/selected_vehicle_provider.dart';
import '../../features/vehicle/presentation/providers/vehicle_providers.dart';

/// Horizontal, scrollable vehicle scope control for the Expenses screen (no [Row] overflow).
class PremiumExpenseVehicleScope extends ConsumerStatefulWidget {
  const PremiumExpenseVehicleScope({super.key});

  @override
  ConsumerState<PremiumExpenseVehicleScope> createState() => _PremiumExpenseVehicleScopeState();
}

class _PremiumExpenseVehicleScopeState extends ConsumerState<PremiumExpenseVehicleScope> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = [];
  var _pendingInitialScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncKeys(int count) {
    if (_itemKeys.length != count) {
      _itemKeys = List.generate(count, (_) => GlobalKey());
    }
  }

  int _indexForSelection(String selectedId, List<Vehicle> vehicles) {
    if (selectedId == kAllVehiclesId) return 0;
    final i = vehicles.indexWhere((v) => v.id == selectedId);
    return i < 0 ? 0 : i + 1;
  }

  void _scrollSelectionIntoView(String selectedId, List<Vehicle> vehicles) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final idx = _indexForSelection(selectedId, vehicles);
      if (idx < 0 || idx >= _itemKeys.length) return;
      final ctx = _itemKeys[idx].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.35,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicleId = ref.watch(selectedVehicleIdProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);

    ref.listen<String>(selectedVehicleIdProvider, (previous, next) {
      if (previous == next) return;
      vehiclesAsync.whenData((vehicles) {
        if (vehicles.isEmpty) return;
        _scrollSelectionIntoView(next, vehicles);
      });
    });

    return vehiclesAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => SizedBox(
        height: 60,
        child: Center(
          child: Text('Vehicles: $e', style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return SizedBox(
            height: 60,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: Text(
                  'Add a vehicle to filter expenses',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final itemCount = vehicles.length + 1;
        _syncKeys(itemCount);
        if (_pendingInitialScroll) {
          _pendingInitialScroll = false;
          _scrollSelectionIntoView(selectedVehicleId, vehicles);
        }

        return SizedBox(
          height: 60,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final id = isAll ? kAllVehiclesId : vehicles[index - 1].id;
              final isSelected = selectedVehicleId == id;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: KeyedSubtree(
                  key: _itemKeys[index],
                  child: _PremiumVehicleChip(
                    label: isAll ? 'All Vehicles' : vehicles[index - 1].name,
                    subLabel: isAll ? 'Combined' : vehicles[index - 1].model,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(selectedVehicleIdProvider.notifier).select(id);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PremiumVehicleChip extends StatelessWidget {
  const _PremiumVehicleChip({
    required this.label,
    required this.subLabel,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subLabel;
  final bool isSelected;
  final VoidCallback onTap;

  static const LinearGradient _selectedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7F00FF), Color(0xFF00C6FF)],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.textPrimary : Theme.of(context).colorScheme.onSurface);
    final subLabelColor = isSelected
        ? Colors.white.withOpacity(0.85)
        : (isDark ? AppColors.textSecondary : Theme.of(context).colorScheme.onSurface.withOpacity(0.65));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 168, minHeight: 52),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected ? _selectedGradient : null,
            color: isSelected
                ? null
                : (isDark ? Colors.white.withOpacity(0.06) : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7)),
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.12) : Theme.of(context).colorScheme.outline.withOpacity(0.35)),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7F00FF).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.15,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  color: subLabelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
