class VehicleDocument {
  final String id;
  final String name;
  final DateTime expiryDate;
  final DateTime createdAt;
  final String? filePath;
  final String? originalFileName;
  final String? fileKind; // image | pdf | other
  final String vehicleId;

  const VehicleDocument({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.createdAt,
    this.filePath,
    this.originalFileName,
    this.fileKind,
    required this.vehicleId,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());
}

