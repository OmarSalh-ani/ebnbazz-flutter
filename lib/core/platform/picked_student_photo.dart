import 'dart:typed_data';

class PickedStudentPhoto {
  const PickedStudentPhoto({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

enum StudentPhotoSource { gallery, camera }
