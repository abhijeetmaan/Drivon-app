import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../domain/entities/vehicle_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/document_model.dart';

class HiveDocumentRepository implements DocumentRepository {
  Future<Box<DocumentModel>> _open() => Hive.openBox<DocumentModel>(HiveBoxes.documents);

  @override
  Stream<List<VehicleDocument>> watchDocuments() async* {
    final box = await _open();
    yield box.values.map((e) => e.toEntity()).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    await for (final _ in box.watch()) {
      yield box.values.map((e) => e.toEntity()).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    }
  }

  @override
  Future<void> addDocument(VehicleDocument document) async {
    final box = await _open();
    await box.put(document.id, DocumentModel.fromEntity(document));
  }

  @override
  Future<void> deleteDocument(String id) async {
    final box = await _open();
    await box.delete(id);
  }

  @override
  Future<void> deleteDocumentsForVehicle(String vehicleId) async {
    final box = await _open();
    for (final key in box.keys.toList()) {
      final m = box.get(key);
      if (m != null && m.vehicleId == vehicleId) {
        await box.delete(key);
      }
    }
  }
}

