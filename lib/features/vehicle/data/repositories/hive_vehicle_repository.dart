import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../models/vehicle_model.dart';

class HiveVehicleRepository implements VehicleRepository {
  Future<Box<VehicleModel>> _open() => Hive.openBox<VehicleModel>(HiveBoxes.vehicles);

  @override
  Stream<List<Vehicle>> watchVehicles() async* {
    final box = await _open();
    yield box.values.map((e) => e.toEntity()).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await for (final _ in box.watch()) {
      yield box.values.map((e) => e.toEntity()).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  Future<void> addVehicle(Vehicle vehicle) async {
    final box = await _open();
    await box.put(vehicle.id, VehicleModel.fromEntity(vehicle));
  }

  @override
  Future<void> deleteVehicle(String id) async {
    final box = await _open();
    await box.delete(id);
  }
}

