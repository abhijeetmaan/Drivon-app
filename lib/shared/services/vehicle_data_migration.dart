import 'package:hive/hive.dart';

import '../../core/constants/hive_boxes.dart';
import '../../features/documents/data/models/document_model.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../../features/trips/data/models/trip_model.dart';
import '../../features/vehicle/data/models/vehicle_model.dart';

/// Opens prefs box and assigns legacy rows (no [vehicleId]) to the oldest vehicle.
Future<void> openAppPrefsAndMigrateVehicleIds() async {
  await Hive.openBox<dynamic>(HiveBoxes.appPrefs);

  final vehicleBox = await Hive.openBox<VehicleModel>(HiveBoxes.vehicles);
  if (vehicleBox.isEmpty) return;

  final sorted = vehicleBox.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final firstId = sorted.first.id;

  final expenseBox = await Hive.openBox<ExpenseModel>(HiveBoxes.expenses);
  for (final key in expenseBox.keys.toList()) {
    final m = expenseBox.get(key);
    if (m != null && m.vehicleId.isEmpty) {
      await expenseBox.put(
        key,
        ExpenseModel(
          id: m.id,
          amount: m.amount,
          type: m.type,
          date: m.date,
          note: m.note,
          vehicleId: firstId,
        ),
      );
    }
  }

  final tripBox = await Hive.openBox<TripModel>(HiveBoxes.trips);
  for (final key in tripBox.keys.toList()) {
    final m = tripBox.get(key);
    if (m != null && m.vehicleId.isEmpty) {
      await tripBox.put(
        key,
        TripModel(
          id: m.id,
          name: m.name,
          createdAt: m.createdAt,
          members: m.members,
          expenses: m.expenses,
          vehicleId: firstId,
        ),
      );
    }
  }

  final docBox = await Hive.openBox<DocumentModel>(HiveBoxes.documents);
  for (final key in docBox.keys.toList()) {
    final m = docBox.get(key);
    if (m != null && m.vehicleId.isEmpty) {
      await docBox.put(
        key,
        DocumentModel(
          id: m.id,
          name: m.name,
          expiryDate: m.expiryDate,
          createdAt: m.createdAt,
          filePath: m.filePath,
          originalFileName: m.originalFileName,
          fileKind: m.fileKind,
          vehicleId: firstId,
        ),
      );
    }
  }
}
