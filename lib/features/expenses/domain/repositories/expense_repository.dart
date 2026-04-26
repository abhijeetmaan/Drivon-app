import '../entities/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpenses();
  Future<void> addExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<void> deleteExpensesForVehicle(String vehicleId);
}

