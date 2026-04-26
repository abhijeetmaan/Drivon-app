import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/documents/data/models/document_model.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../../features/profile/data/models/profile_model.dart';
import '../../features/trips/data/models/trip_model.dart';
import '../../features/vehicle/data/models/vehicle_model.dart';
import 'vehicle_data_migration.dart';

Future<void> bootstrap(ProviderContainer container) async {
  // Centralized init makes startup predictable (and testable).
  await Hive.initFlutter();

  // Register adapters (keep IDs stable forever).
  if (!Hive.isAdapterRegistered(VehicleModelAdapter.typeIdValue)) {
    Hive.registerAdapter(VehicleModelAdapter());
  }
  if (!Hive.isAdapterRegistered(ExpenseModelAdapter.typeIdValue)) {
    Hive.registerAdapter(ExpenseModelAdapter());
  }
  if (!Hive.isAdapterRegistered(DocumentModelAdapter.typeIdValue)) {
    Hive.registerAdapter(DocumentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(ProfileModelAdapter.typeIdValue)) {
    Hive.registerAdapter(ProfileModelAdapter());
  }
  if (!Hive.isAdapterRegistered(TripExpenseModelAdapter.typeIdValue)) {
    Hive.registerAdapter(TripExpenseModelAdapter());
  }
  if (!Hive.isAdapterRegistered(TripModelAdapter.typeIdValue)) {
    Hive.registerAdapter(TripModelAdapter());
  }

  await openAppPrefsAndMigrateVehicleIds();
}

