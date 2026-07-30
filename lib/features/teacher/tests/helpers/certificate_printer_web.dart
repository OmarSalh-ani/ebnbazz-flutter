// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> openCertificateForPrint(String htmlContent, {String? title}) async {
  final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Future<void>.delayed(const Duration(minutes: 1), () {
    html.Url.revokeObjectUrl(url);
  });
}
