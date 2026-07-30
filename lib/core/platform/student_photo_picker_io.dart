import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'picked_student_photo.dart';

const _channel = MethodChannel('com.alsalhani.ebnbazz/student_photo_picker');

Future<PickedStudentPhoto?> pickStudentPhoto(StudentPhotoSource source) async {
  if (Platform.isAndroid) {
    return _pickAndroid(source);
  }
  return _pickWithImagePicker(source);
}

Future<PickedStudentPhoto?> _pickAndroid(StudentPhotoSource source) async {
  try {
    final method = source == StudentPhotoSource.gallery
        ? 'pickFromGallery'
        : 'takePhoto';
    final result = await _channel.invokeMethod<dynamic>(method);
    if (result == null) return null;

    final path = result is Map ? result['path'] as String? : null;
    if (path == null || path.isEmpty) return null;

    final bytes = await File(path).readAsBytes();
    return PickedStudentPhoto(
      bytes: bytes,
      fileName: path.split(RegExp(r'[/\\]')).last,
    );
  } on PlatformException catch (e) {
    if (e.code == 'cancelled') return null;
    rethrow;
  }
}

Future<PickedStudentPhoto?> _pickWithImagePicker(StudentPhotoSource source) async {
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
