// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveExportedFile(Uint8List bytes, String fileName) async {
  if (bytes.length < 5 ||
      bytes[0] != 0x25 ||
      bytes[1] != 0x50 ||
      bytes[2] != 0x44 ||
      bytes[3] != 0x46) {
    throw Exception('الملف المستلم ليس شهادة PDF صالحة');
  }

  var name = fileName.trim();
  if (name.isEmpty) name = 'certificate.pdf';
  name = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (!name.toLowerCase().endsWith('.pdf')) {
    name = '$name.pdf';
  }

  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = name
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
