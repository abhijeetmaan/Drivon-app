import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../documents/domain/repositories/document_repository.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../data/repositories/hive_vehicle_repository.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return HiveVehicleRepository();
});

final vehiclesProvider = StreamProvider.autoDispose<List<Vehicle>>((ref) {
  return ref.watch(vehicleRepositoryProvider).watchVehicles();
});

final vehicleActionsProvider = Provider<VehicleActions>((ref) {
  return VehicleActions(
    vehicleRepo: ref.watch(vehicleRepositoryProvider),
    expenseRepo: ref.watch(expenseRepositoryProvider),
    tripRepo: ref.watch(tripRepositoryProvider),
    documentRepo: ref.watch(documentRepositoryProvider),
  );
});

class VehicleActions {
  final VehicleRepository vehicleRepo;
  final ExpenseRepository expenseRepo;
  final TripRepository tripRepo;
  final DocumentRepository documentRepo;

  VehicleActions({
    required this.vehicleRepo,
    required this.expenseRepo,
    required this.tripRepo,
    required this.documentRepo,
  });

  Future<void> addVehicle({
    required String name,
    required String model,
    required String fuelType,
  }) async {
    final vehicle = Vehicle(
      id: const Uuid().v4(),
      name: name.trim(),
      model: model.trim(),
      fuelType: fuelType.trim(),
      createdAt: DateTime.now(),
    );
    await vehicleRepo.addVehicle(vehicle);
  }

  /// Deletes the vehicle and all expenses, trips, and documents tied to it.
  Future<void> deleteVehicle(String id) async {
    await expenseRepo.deleteExpensesForVehicle(id);
    await tripRepo.deleteTripsForVehicle(id);
    await documentRepo.deleteDocumentsForVehicle(id);
    await vehicleRepo.deleteVehicle(id);
  }
}
