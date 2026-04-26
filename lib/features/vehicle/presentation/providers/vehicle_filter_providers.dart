import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/vehicle_scope.dart';
import '../../../documents/domain/entities/vehicle_document.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import 'selected_vehicle_provider.dart';

List<Expense> _filterExpenses(List<Expense> all, String scope) {
  if (scope == kAllVehiclesId) return all;
  return all.where((e) => e.vehicleId == scope).toList();
}

List<Trip> _filterTrips(List<Trip> all, String scope) {
  if (scope == kAllVehiclesId) return all;
  return all.where((t) => t.vehicleId == scope).toList();
}

List<VehicleDocument> _filterDocuments(List<VehicleDocument> all, String scope) {
  if (scope == kAllVehiclesId) return all;
  return all.where((d) => d.vehicleId == scope).toList();
}

/// Expenses for the current vehicle scope (recomputes when data or scope changes).
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final scope = ref.watch(selectedVehicleIdProvider);
  final async = ref.watch(expensesProvider);
  return async.when(
    data: (list) => _filterExpenses(list, scope),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

final filteredTripsProvider = Provider<List<Trip>>((ref) {
  final scope = ref.watch(selectedVehicleIdProvider);
  final async = ref.watch(tripsProvider);
  return async.when(
    data: (list) => _filterTrips(list, scope),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

final filteredDocumentsProvider = Provider<List<VehicleDocument>>((ref) {
  final scope = ref.watch(selectedVehicleIdProvider);
  final async = ref.watch(documentsProvider);
  return async.when(
    data: (list) => _filterDocuments(list, scope),
    loading: () => const [],
    error: (_, __) => const [],
  );
});
