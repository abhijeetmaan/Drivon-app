import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/vehicle_document.dart';
import '../../../../shared/dialogs/delete_confirmation.dart' show showPremiumDeleteDialog;
import '../../../../shared/widgets/gradient_card.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../providers/document_providers.dart';

class DocumentPreviewScreen extends ConsumerWidget {
  final VehicleDocument document;
  const DocumentPreviewScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = _effectiveExtension(document);
    final icon = _iconForExt(ext);
    final isPdf = _isPdf(document, ext);
    final isImage = _isImage(document, ext);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(
            tooltip: 'Delete document',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showPremiumDeleteDialog(
                context,
                title: 'Delete Document?',
                onConfirm: () async {
                  await ref.read(documentActionsProvider).deleteDocument(document.id);
                },
                successMessage: 'Document deleted',
              );
              if (ok && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.9),
              Colors.blueAccent.withOpacity(0.55),
              Colors.purpleAccent.withOpacity(0.45),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.16),
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        document.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Expiry: ${DateFormat('MMM d, yyyy').format(document.expiryDate)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.85)),
                ),
                const SizedBox(height: 6),
                Text(
                  document.originalFileName == null ? '—' : document.originalFileName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.75)),
                ),
                if (document.filePath != null && document.filePath!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    p.basename(document.filePath!),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          CustomCard(
            prominent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preview', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildPreview(context, document, ext, icon, isImage, isPdf),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildPreview(
  BuildContext context,
  VehicleDocument doc,
  String ext,
  IconData icon,
  bool isImage,
  bool isPdf,
) {
  final path = doc.filePath?.trim();
  if (path == null || path.isEmpty) {
    return _previewPlaceholder(
      context,
      Icons.insert_drive_file_outlined,
      'No file attached',
      'This document has no saved file path.',
    );
  }

  final file = File(path);
  if (!file.existsSync()) {
    return _previewPlaceholder(
      context,
      Icons.broken_image_outlined,
      'File not found',
      'The file may have been removed or is unavailable.',
    );
  }

  if (isImage) {
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _previewPlaceholder(
        context,
        Icons.broken_image_outlined,
        'Could not load image',
        doc.originalFileName ?? doc.name,
      ),
    );
  }

  if (isPdf) {
    return _previewPlaceholder(
      context,
      Icons.picture_as_pdf_outlined,
      'PDF preview',
      'Open this file with a PDF viewer on your device.\n${p.basename(path)}',
      multilineSubtitle: true,
    );
  }

  final label = doc.originalFileName ?? pFallback(doc.name);
  return _previewPlaceholder(context, icon, label, p.basename(path));
}

Widget _previewPlaceholder(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle, {
  bool multilineSubtitle = false,
}) {
  return Container(
    color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: multilineSubtitle ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

String pFallback(String s) => s.trim().isEmpty ? 'document' : s.trim();

String _effectiveExtension(VehicleDocument d) {
  final path = d.filePath;
  if (path != null && path.isNotEmpty) {
    final e = p.extension(path).toLowerCase();
    if (e.length > 1) return e.substring(1);
  }
  for (final name in [d.originalFileName, d.name]) {
    if (name != null && name.isNotEmpty) {
      final i = name.lastIndexOf('.');
      if (i != -1 && i < name.length - 1) {
        return name.substring(i + 1).toLowerCase();
      }
    }
  }
  return 'doc';
}

IconData _iconForExt(String ext) {
  if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
  if (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp' || ext == 'gif') {
    return Icons.image_outlined;
  }
  return Icons.description_outlined;
}

bool _isPdf(VehicleDocument d, String ext) => d.fileKind == 'pdf' || ext == 'pdf';

bool _isImage(VehicleDocument d, String ext) {
  if (d.fileKind == 'image') return true;
  return ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp' || ext == 'gif';
}

