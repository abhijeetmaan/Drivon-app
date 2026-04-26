import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalFileStore {
  LocalFileStore._();

  static Future<String> persistFile({
    required String sourcePath,
    required String namespace,
    String? preferredName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final base = Directory(p.join(dir.path, 'autopilot', namespace));
    if (!await base.exists()) {
      await base.create(recursive: true);
    }

    final src = File(sourcePath);
    final ext = p.extension(sourcePath);
    final safeName = _safeFileName(preferredName ?? p.basenameWithoutExtension(sourcePath));
    final ts = DateTime.now().millisecondsSinceEpoch;
    final destPath = p.join(base.path, '${safeName}_$ts$ext');

    final copied = await src.copy(destPath);
    return copied.path;
  }

  static String _safeFileName(String s) {
    final trimmed = s.trim().isEmpty ? 'file' : s.trim();
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9_\\-]+'), '_');
  }
}

