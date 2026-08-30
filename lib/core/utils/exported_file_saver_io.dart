import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveExportedFile(Uint8List bytes, String fileName) async {
  if (!_isPdfBytes(bytes)) {
    throw const FileSystemException('الملف المستلم ليس شهادة PDF صالحة');
  }

  final safeName = _asciiFileName(fileName);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);
  if (!await file.exists() || await file.length() != bytes.length) {
    throw const FileSystemException('تعذر تجهيز الملف للمشاركة');
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf', name: safeName)],
      fileNameOverrides: [safeName],
      subject: 'شهادة اختبار',
    ),
  );
}

bool _isPdfBytes(Uint8List bytes) {
  if (bytes.length < 5) return false;
  // %PDF
  return bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
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
