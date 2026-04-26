import '../entities/trip.dart';

abstract class TripRepository {
  Stream<List<Trip>> watchTrips();
  Future<void> addTrip(Trip trip);
  Future<void> updateTrip(Trip trip);
  Future<void> deleteTrip(String id);
  Future<void> deleteTripsForVehicle(String vehicleId);
}

