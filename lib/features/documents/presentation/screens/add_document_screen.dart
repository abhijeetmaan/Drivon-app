import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/vehicle_scope.dart';
import '../../../../shared/services/local_file_store.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/presentation/providers/selected_vehicle_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_providers.dart';
import '../providers/document_providers.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));
  bool _saving = false;
  String? _vehicleId;

  String? _pickedPath;
  String? _pickedOriginalName;
  String? _pickedKind; // image | pdf | other

  static ButtonStyle get _saveButtonStyle => FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<bool> _ensureMediaPermission() async {
    final status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<void> _pickImage() async {
    final ok = await _ensureMediaPermission();
    if (!ok) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission required'),
          content: const Text('Please allow photo/media access to pick an image.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (img == null) return;
    setState(() {
      _pickedPath = img.path;
      _pickedOriginalName = img.name;
      _pickedKind = 'image';
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'webp'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    if (f.path == null) return;
    final name = f.name;
    final lower = name.toLowerCase();
    final kind = lower.endsWith('.pdf')
        ? 'pdf'
        : (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp'))
            ? 'image'
            : 'other';
    setState(() {
      _pickedPath = f.path;
      _pickedOriginalName = name;
      _pickedKind = kind;
    });
  }

  void _syncVehiclePick(List<Vehicle> vehicles) {
    if (vehicles.isEmpty) return;
    final scope = ref.read(selectedVehicleIdProvider);
    if (_vehicleId != null && vehicles.any((v) => v.id == _vehicleId)) return;
    if (scope != kAllVehiclesId && vehicles.any((v) => v.id == scope)) {
      _vehicleId = scope;
      return;
    }
    _vehicleId = vehicles.first.id;
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    final vehicles = ref.read(vehiclesProvider).valueOrNull ?? [];
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vehicle before uploading documents.')),
      );
      return;
    }
    _syncVehiclePick(vehicles);
    final vid = _vehicleId;
    if (vid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a vehicle')));
      return;
    }
    if (_pickedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file to upload')));
      return;
    }

    setState(() => _saving = true);
    try {
      final storedPath = await LocalFileStore.persistFile(
        sourcePath: _pickedPath!,
        namespace: 'documents',
        preferredName: _name.text,
      );
      await ref.read(documentActionsProvider).addDocument(
            name: _name.text,
            expiryDate: _expiry,
            vehicleId: vid,
            filePath: storedPath,
            originalFileName: _pickedOriginalName,
            fileKind: _pickedKind,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded')));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save document: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPad = mq.viewInsets.bottom + mq.padding.bottom + 24;
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.deferToChild,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('Upload Document')),
        body: SafeArea(
          child: vehiclesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load vehicles: $e')),
            data: (vehicles) {
              _syncVehiclePick(vehicles);
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: bottomPad,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (vehicles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Add a vehicle first — documents are stored per vehicle.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _vehicleId,
                            decoration: const InputDecoration(labelText: 'Vehicle'),
                            items: [
                              for (final v in vehicles)
                                DropdownMenuItem(value: v.id, child: Text('${v.name} · ${v.model}')),
                            ],
                            onChanged: (v) => setState(() => _vehicleId = v),
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Document name (e.g. Insurance, PUC)'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 12),
                    CustomCard(
                      prominent: true,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.upload_file_rounded),
                              const SizedBox(width: 10),
                              const Expanded(child: Text('Select file')),
                              TextButton(onPressed: _pickFile, child: const Text('Pick file')),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.image_outlined),
                              const SizedBox(width: 10),
                              const Expanded(child: Text('Select image')),
                              TextButton(onPressed: _pickImage, child: const Text('Pick image')),
                            ],
                          ),
                          if (_pickedOriginalName != null || _pickedPath != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  _pickedKind == 'image'
                                      ? Icons.image_outlined
                                      : _pickedKind == 'pdf'
                                          ? Icons.picture_as_pdf_outlined
                                          : Icons.description_outlined,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _pickedOriginalName ?? _pickedPath!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _pickedPath = null;
                                    _pickedOriginalName = null;
                                    _pickedKind = null;
                                  }),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Expiry date'),
                      subtitle: Text(DateFormat('MMM d, yyyy').format(_expiry)),
                      trailing: TextButton(onPressed: _pickExpiry, child: const Text('Pick')),
                    ),
                    const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Save document',
                          isLoading: _saving,
                          style: _saveButtonStyle,
                          onPressed: vehicles.isEmpty ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
