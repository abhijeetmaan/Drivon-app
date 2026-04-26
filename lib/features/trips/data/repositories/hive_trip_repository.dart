import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../models/trip_model.dart';

class HiveTripRepository implements TripRepository {
  Future<Box<TripModel>> _open() => Hive.openBox<TripModel>(HiveBoxes.trips);

  @override
  Stream<List<Trip>> watchTrips() async* {
    final box = await _open();
    yield box.values.map((e) => e.toEntity()).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await for (final _ in box.watch()) {
      yield box.values.map((e) => e.toEntity()).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  Future<void> addTrip(Trip trip) async {
    final box = await _open();
    await box.put(trip.id, TripModel.fromEntity(trip));
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    final box = await _open();
    await box.put(trip.id, TripModel.fromEntity(trip));
  }

  @override
  Future<void> deleteTrip(String id) async {
    final box = await _open();
    await box.delete(id);
  }

  @override
  Future<void> deleteTripsForVehicle(String vehicleId) async {
    final box = await _open();
    for (final key in box.keys.toList()) {
      final m = box.get(key);
      if (m != null && m.vehicleId == vehicleId) {
        await box.delete(key);
      }
    }
  }
}

