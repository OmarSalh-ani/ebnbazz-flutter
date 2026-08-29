import 'dart:typed_data';

import 'exported_file_saver_stub.dart'
    if (dart.library.io) 'exported_file_saver_io.dart'
    if (dart.library.html) 'exported_file_saver_web.dart' as impl;

Future<void> saveExportedFile(Uint8List bytes, String fileName) =>
    impl.saveExportedFile(bytes, fileName);
