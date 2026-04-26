import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/hive_document_repository.dart';
import '../../domain/entities/vehicle_document.dart';
import '../../domain/repositories/document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return HiveDocumentRepository();
});

final documentsProvider = StreamProvider.autoDispose<List<VehicleDocument>>((ref) {
  return ref.watch(documentRepositoryProvider).watchDocuments();
});

final documentActionsProvider = Provider<DocumentActions>((ref) {
  return DocumentActions(repo: ref.watch(documentRepositoryProvider));
});

class DocumentActions {
  final DocumentRepository repo;
  DocumentActions({required this.repo});

  Future<void> addDocument({
    required String name,
    required DateTime expiryDate,
    required String vehicleId,
    String? filePath,
    String? originalFileName,
    String? fileKind,
  }) async {
    final doc = VehicleDocument(
      id: const Uuid().v4(),
      name: name.trim(),
      expiryDate: expiryDate,
      createdAt: DateTime.now(),
      filePath: filePath,
      originalFileName: originalFileName,
      fileKind: fileKind,
      vehicleId: vehicleId,
    );
    await repo.addDocument(doc);
  }

  Future<void> deleteDocument(String id) async {
    await repo.deleteDocument(id);
  }
}

