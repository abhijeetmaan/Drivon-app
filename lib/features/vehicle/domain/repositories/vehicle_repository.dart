import '../entities/vehicle.dart';

abstract class VehicleRepository {
  Stream<List<Vehicle>> watchVehicles();
  Future<void> addVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(String id);
}

