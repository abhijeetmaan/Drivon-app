import 'package:hive/hive.dart';

import '../../domain/entities/vehicle.dart';

@HiveType(typeId: 10)
class VehicleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String model;

  @HiveField(3)
  final String fuelType;

  @HiveField(4)
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.name,
    required this.model,
    required this.fuelType,
    required this.createdAt,
  });

  Vehicle toEntity() => Vehicle(
        id: id,
        name: name,
        model: model,
        fuelType: fuelType,
        createdAt: createdAt,
      );

  static VehicleModel fromEntity(Vehicle v) => VehicleModel(
        id: v.id,
        name: v.name,
        model: v.model,
        fuelType: v.fuelType,
        createdAt: v.createdAt,
      );
}

class VehicleModelAdapter extends TypeAdapter<VehicleModel> {
  static const int typeIdValue = 10;

  @override
  int get typeId => typeIdValue;

  @override
  VehicleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleModel(
      id: fields[0] as String,
      name: fields[1] as String,
      model: fields[2] as String,
      fuelType: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.model)
      ..writeByte(3)
      ..write(obj.fuelType)
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}

