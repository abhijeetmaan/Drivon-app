import 'package:hive/hive.dart';

import '../../domain/entities/vehicle_document.dart';

@HiveType(typeId: 12)
class DocumentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime expiryDate;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? filePath;

  @HiveField(5)
  final String? originalFileName;

  @HiveField(6)
  final String? fileKind;

  @HiveField(7)
  final String vehicleId;

  DocumentModel({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.createdAt,
    this.filePath,
    this.originalFileName,
    this.fileKind,
    this.vehicleId = '',
  });

  VehicleDocument toEntity() => VehicleDocument(
        id: id,
        name: name,
        expiryDate: expiryDate,
        createdAt: createdAt,
        filePath: filePath,
        originalFileName: originalFileName,
        fileKind: fileKind,
        vehicleId: vehicleId,
      );
  static DocumentModel fromEntity(VehicleDocument d) =>
      DocumentModel(
        id: d.id,
        name: d.name,
        expiryDate: d.expiryDate,
        createdAt: d.createdAt,
        filePath: d.filePath,
        originalFileName: d.originalFileName,
        fileKind: d.fileKind,
        vehicleId: d.vehicleId,
      );
}

class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
  static const int typeIdValue = 12;

  @override
  int get typeId => typeIdValue;

  @override
  DocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    String? optStr(int key) {
      final v = fields[key];
      if (v == null) return null;
      return v is String ? v : null;
    }

    return DocumentModel(
      id: fields[0] as String,
      name: fields[1] as String,
      expiryDate: fields[2] as DateTime,
      createdAt: fields[3] as DateTime,
      filePath: optStr(4),
      originalFileName: optStr(5),
      fileKind: optStr(6),
      vehicleId: fields[7] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, DocumentModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.expiryDate)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.filePath)
      ..writeByte(5)
      ..write(obj.originalFileName)
      ..writeByte(6)
      ..write(obj.fileKind)
      ..writeByte(7)
      ..write(obj.vehicleId);
  }
}

