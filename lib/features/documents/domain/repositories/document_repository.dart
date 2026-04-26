import '../entities/vehicle_document.dart';

abstract class DocumentRepository {
  Stream<List<VehicleDocument>> watchDocuments();
  Future<void> addDocument(VehicleDocument document);
  Future<void> deleteDocument(String id);
  Future<void> deleteDocumentsForVehicle(String vehicleId);
}

