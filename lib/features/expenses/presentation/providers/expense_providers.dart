import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/hive_expense_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return HiveExpenseRepository();
});

final expensesProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchExpenses();
});

final expenseActionsProvider = Provider<ExpenseActions>((ref) {
  return ExpenseActions(repo: ref.watch(expenseRepositoryProvider));
});

class ExpenseActions {
  final ExpenseRepository repo;
  ExpenseActions({required this.repo});

  Future<void> addExpense({
    required double amount,
    required String type,
    required DateTime date,
    required String note,
    required String vehicleId,
  }) async {
    final expense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      type: type.trim(),
      date: date,
      note: note.trim(),
      vehicleId: vehicleId,
    );
    await repo.addExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await repo.deleteExpense(id);
  }
}

