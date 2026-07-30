import 'picked_student_photo.dart';
import 'student_photo_picker_stub.dart'
    if (dart.library.io) 'student_photo_picker_io.dart'
    if (dart.library.html) 'student_photo_picker_web.dart' as impl;

export 'picked_student_photo.dart';

class StudentPhotoPicker {
  StudentPhotoPicker._();

  static Future<PickedStudentPhoto?> pick(StudentPhotoSource source) {
    return impl.pickStudentPhoto(source);
  }
}
