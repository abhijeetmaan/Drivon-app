class Trip {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> members;
  final List<TripExpense> expenses;
  final String vehicleId;

  const Trip({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.members,
    required this.expenses,
    required this.vehicleId,
  });

  /// Display title (alias for [name]).
  String get title => name;
}

class TripExpense {
  final String id;
  final String paidBy;
  final double amount;
  final String note;
  final DateTime createdAt;

  const TripExpense({
    required this.id,
    required this.paidBy,
    required this.amount,
    required this.note,
    required this.createdAt,
  });
}

