import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> openCertificateForPrint(String html, {String? title}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/test_certificate.html');
  await file.writeAsString(html, flush: true);

  await Share.shareXFiles(
    [XFile(file.path)],
    subject: title ?? 'شهادة اختبار',
    text: 'شهادة اختبار الطالب',
  );
}
