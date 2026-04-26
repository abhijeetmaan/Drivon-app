class Expense {
  final String id;
  final double amount;
  final String type;
  final DateTime date;
  final String note;
  final String vehicleId;

  const Expense({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.note,
    required this.vehicleId,
  });
}

