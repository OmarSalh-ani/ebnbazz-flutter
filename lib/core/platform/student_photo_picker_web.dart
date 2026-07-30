import 'package:image_picker/image_picker.dart';

import 'picked_student_photo.dart';

Future<PickedStudentPhoto?> pickStudentPhoto(StudentPhotoSource source) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source == StudentPhotoSource.gallery
        ? ImageSource.gallery
        : ImageSource.camera,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );

  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  final name = picked.name.isNotEmpty ? picked.name : 'photo.jpg';
  return PickedStudentPhoto(bytes: bytes, fileName: name);
}
