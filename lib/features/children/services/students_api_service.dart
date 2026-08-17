import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/picked_student_photo.dart';
import '../../../shared/models/paged_result.dart';
import '../../memorizing_archive/models/memorizing_archive_item.dart';
import '../models/child_model.dart';

class StudentsApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ChildModel>> getStudents() async {
    try {
      final response = await _dio.get('/api/students');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ChildModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل بيانات الأبناء');
    }
  }

  Future<ChildModel> getStudentProfile(String studentId) async {
    try {
      final response = await _dio.get('/api/students/$studentId');
      return ChildModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل ملف الابن');
    }
  }

  Future<ChildModel> updateStudent(String studentId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/students/$studentId', data: data);
      return ChildModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر حفظ التغييرات');
    }
  }

  Future<ChildModel> uploadStudentPhoto(
    String studentId,
    PickedStudentPhoto photo,
  ) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          photo.bytes,
          filename: photo.fileName,
        ),
      });
      final response = await _dio.post(
        '/api/students/$studentId/photo',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ChildModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر رفع الصورة');
    }
  }

  Future<ChildModel> addStudent(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/students', data: data);
      return ChildModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر إضافة الابن');
    }
  }

  Future<PagedResult<MemorizingArchiveItem>> getMemorizingArchive(
    String studentId, {
    required int page,
    int pageSize = 20,
    String? surahSearch,
  }) async {
    try {
      final trimmed = surahSearch?.trim();
      final response = await _dio.get(
        '/api/students/$studentId/memorizing-archive',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (trimmed != null && trimmed.isNotEmpty) 'surahSearch': trimmed,
        },
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        MemorizingArchiveItem.fromJson,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل أرشيف الحفظ');
    }
  }
}
