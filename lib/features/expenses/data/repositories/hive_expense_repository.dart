import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';

class HiveExpenseRepository implements ExpenseRepository {
  Future<Box<ExpenseModel>> _open() => Hive.openBox<ExpenseModel>(HiveBoxes.expenses);

  @override
  Stream<List<Expense>> watchExpenses() async* {
    final box = await _open();
    yield box.values.map((e) => e.toEntity()).toList()..sort((a, b) => b.date.compareTo(a.date));
    await for (final _ in box.watch()) {
      yield box.values.map((e) => e.toEntity()).toList()..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    final box = await _open();
    await box.put(expense.id, ExpenseModel.fromEntity(expense));
  }

  @override
  Future<void> deleteExpense(String id) async {
    final box = await _open();
    await box.delete(id);
  }

  @override
  Future<void> deleteExpensesForVehicle(String vehicleId) async {
    final box = await _open();
    for (final key in box.keys.toList()) {
      final m = box.get(key);
      if (m != null && m.vehicleId == vehicleId) {
        await box.delete(key);
      }
    }
  }
}

