import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/constants/vehicle_scope.dart';
import '../../domain/entities/vehicle.dart';
import 'vehicle_providers.dart';

/// Persists the dashboard scope: [kAllVehiclesId] or a [Vehicle.id].
class SelectedVehicleIdNotifier extends Notifier<String> {
  static const _storageKey = 'selected_vehicle_id';

  void _persist(String value) {
    Hive.box<dynamic>(HiveBoxes.appPrefs).put(_storageKey, value);
  }

  @override
  String build() {
    ref.listen<AsyncValue<List<Vehicle>>>(vehiclesProvider, (_, next) {
      final vehicles = next.valueOrNull;
      if (vehicles == null) return;
      if (vehicles.isEmpty) {
        if (state != kAllVehiclesId) {
          state = kAllVehiclesId;
          _persist(state);
        }
        return;
      }
      if (state != kAllVehiclesId && !vehicles.any((v) => v.id == state)) {
        state = vehicles.first.id;
        _persist(state);
      }
    });

    final raw = Hive.box<dynamic>(HiveBoxes.appPrefs).get(_storageKey);
    final stored = raw is String ? raw : null;
    if (stored == null || stored.isEmpty) return kAllVehiclesId;
    return stored;
  }

  void select(String vehicleIdOrAll) {
    state = vehicleIdOrAll;
    _persist(vehicleIdOrAll);
  }
}

final selectedVehicleIdProvider =
    NotifierProvider<SelectedVehicleIdNotifier, String>(SelectedVehicleIdNotifier.new);

/// Resolves which [vehicleId] to attach to new records when scope is "all".
String? defaultVehicleIdForNewData(WidgetRef ref) {
  final scope = ref.read(selectedVehicleIdProvider);
  if (scope != kAllVehiclesId) return scope;
  final vehicles = ref.read(vehiclesProvider).valueOrNull ?? [];
  if (vehicles.isEmpty) return null;
  final sorted = [...vehicles]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return sorted.first.id;
}
