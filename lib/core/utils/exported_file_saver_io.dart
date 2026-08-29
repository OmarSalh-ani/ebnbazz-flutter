import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<void> saveExportedFile(Uint8List bytes, String fileName) async {
  final safeName = _asciiFileName(fileName);
  final candidates = await _candidateDirectories();

  Object? lastError;
  for (final dir in candidates) {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(bytes, flush: true);
      return;
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError ?? FileSystemException('تعذر حفظ الملف');
}

String _asciiFileName(String fileName) {
  var name = fileName.trim();
  if (name.isEmpty) name = 'certificate.pdf';
  name = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (!name.toLowerCase().endsWith('.pdf')) {
    name = '$name.pdf';
  }
  return name;
}

Future<List<Directory>> _candidateDirectories() async {
  final dirs = <Directory>[];

  if (Platform.isAndroid) {
    dirs.add(Directory('/storage/emulated/0/Download'));
  }

  try {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) dirs.add(downloads);
  } catch (_) {
    // iOS and some platforms do not expose a public Downloads folder.
  }

  if (Platform.isAndroid) {
    try {
      final external = await getExternalStorageDirectory();
      if (external != null) dirs.add(external);
    } catch (_) {}
  }

  dirs.add(await getApplicationDocumentsDirectory());
  return dirs;
}
