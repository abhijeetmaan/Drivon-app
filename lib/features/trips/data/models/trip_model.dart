import 'package:hive/hive.dart';

import '../../domain/entities/trip.dart';

@HiveType(typeId: 20)
class TripExpenseModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String paidBy;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String note;

  @HiveField(4)
  final DateTime createdAt;

  TripExpenseModel({
    required this.id,
    required this.paidBy,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  TripExpense toEntity() => TripExpense(id: id, paidBy: paidBy, amount: amount, note: note, createdAt: createdAt);
  static TripExpenseModel fromEntity(TripExpense e) =>
      TripExpenseModel(id: e.id, paidBy: e.paidBy, amount: e.amount, note: e.note, createdAt: e.createdAt);
}

class TripExpenseModelAdapter extends TypeAdapter<TripExpenseModel> {
  static const int typeIdValue = 20;
  @override
  int get typeId => typeIdValue;

  @override
  TripExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripExpenseModel(
      id: fields[0] as String,
      paidBy: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      note: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TripExpenseModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.paidBy)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}

@HiveType(typeId: 13)
class TripModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final List<String> members;

  @HiveField(4)
  final List<TripExpenseModel> expenses;

  @HiveField(5)
  final String vehicleId;

  TripModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.members,
    required this.expenses,
    this.vehicleId = '',
  });

  Trip toEntity() => Trip(
        id: id,
        name: name,
        createdAt: createdAt,
        members: List<String>.from(members),
        expenses: expenses.map((e) => e.toEntity()).toList(),
        vehicleId: vehicleId,
      );

  static TripModel fromEntity(Trip t) => TripModel(
        id: t.id,
        name: t.name,
        createdAt: t.createdAt,
        members: List<String>.from(t.members),
        expenses: t.expenses.map(TripExpenseModel.fromEntity).toList(),
        vehicleId: t.vehicleId,
      );
}

class TripModelAdapter extends TypeAdapter<TripModel> {
  static const int typeIdValue = 13;

  @override
  int get typeId => typeIdValue;

  @override
  TripModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripModel(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      members: (fields[3] as List).cast<String>(),
      expenses: (fields[4] as List).cast<TripExpenseModel>(),
      vehicleId: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, TripModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.members)
      ..writeByte(4)
      ..write(obj.expenses)
      ..writeByte(5)
      ..write(obj.vehicleId);
  }
}

