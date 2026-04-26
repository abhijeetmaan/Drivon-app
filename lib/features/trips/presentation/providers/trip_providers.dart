import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/hive_trip_repository.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) => HiveTripRepository());

final tripsProvider = StreamProvider.autoDispose<List<Trip>>((ref) {
  return ref.watch(tripRepositoryProvider).watchTrips();
});

final tripActionsProvider = Provider<TripActions>((ref) {
  return TripActions(repo: ref.watch(tripRepositoryProvider));
});

class TripActions {
  final TripRepository repo;
  TripActions({required this.repo});

  Future<void> createTrip({required String name, required String vehicleId}) async {
    final trip = Trip(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
      members: const [],
      expenses: const [],
      vehicleId: vehicleId,
    );
    await repo.addTrip(trip);
  }

  Future<void> addMember(Trip trip, String member) async {
    final m = member.trim();
    if (m.isEmpty) return;
    final next = Trip(
      id: trip.id,
      name: trip.name,
      createdAt: trip.createdAt,
      members: {...trip.members, m}.toList(),
      expenses: trip.expenses,
      vehicleId: trip.vehicleId,
    );
    await repo.updateTrip(next);
  }

  Future<void> addExpense({
    required Trip trip,
    required String paidBy,
    required double amount,
    required String note,
  }) async {
    final e = TripExpense(
      id: const Uuid().v4(),
      paidBy: paidBy.trim(),
      amount: amount,
      note: note.trim(),
      createdAt: DateTime.now(),
    );
    final next = Trip(
      id: trip.id,
      name: trip.name,
      createdAt: trip.createdAt,
      members: trip.members,
      expenses: [...trip.expenses, e],
      vehicleId: trip.vehicleId,
    );
    await repo.updateTrip(next);
  }

  Future<void> deleteTrip(String id) => repo.deleteTrip(id);

  Future<void> removeMember(Trip trip, String member) async {
    final m = member.trim();
    final next = Trip(
      id: trip.id,
      name: trip.name,
      createdAt: trip.createdAt,
      members: trip.members.where((x) => x != m).toList(),
      expenses: trip.expenses,
      vehicleId: trip.vehicleId,
    );
    await repo.updateTrip(next);
  }

  Future<void> removeTripExpense(Trip trip, String expenseId) async {
    final next = Trip(
      id: trip.id,
      name: trip.name,
      createdAt: trip.createdAt,
      members: trip.members,
      expenses: trip.expenses.where((e) => e.id != expenseId).toList(),
      vehicleId: trip.vehicleId,
    );
    await repo.updateTrip(next);
  }
}
