import 'package:hive/hive.dart';

import '../../domain/entities/expense.dart';

@HiveType(typeId: 11)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String note;

  @HiveField(5)
  final String vehicleId;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.note,
    this.vehicleId = '',
  });

  Expense toEntity() =>
      Expense(id: id, amount: amount, type: type, date: date, note: note, vehicleId: vehicleId);

  static ExpenseModel fromEntity(Expense e) => ExpenseModel(
        id: e.id,
        amount: e.amount,
        type: e.type,
        date: e.date,
        note: e.note,
        vehicleId: e.vehicleId,
      );
}

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  static const int typeIdValue = 11;

  @override
  int get typeId => typeIdValue;

  @override
  ExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseModel(
      id: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      type: fields[2] as String,
      date: fields[3] as DateTime,
      note: fields[4] as String,
      vehicleId: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.vehicleId);
  }
}

