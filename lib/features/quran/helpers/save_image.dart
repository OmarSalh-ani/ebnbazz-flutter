import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<File> saveImageToTempDirectory(Uint8List imageBytes) async {
  final tempDir = await getTemporaryDirectory();
  final tempFilePath = '${tempDir.path}/temp_image.png';

  final file = File(tempFilePath);
  await file.writeAsBytes(imageBytes);

  return file;
}
