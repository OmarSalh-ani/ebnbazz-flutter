import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/picked_student_photo.dart';
import '../../memorizing_archive/models/memorizing_archive_item.dart';
import '../models/child_model.dart';
import '../models/student_plan_models.dart';
import '../models/student_quran_assignment.dart';

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

  /// Current memorize/revise plan from teacher for this student.
  Future<StudentQuranAssignment> getQuranAssignment(String studentId) async {
    try {
      final response =
          await _dio.get('/api/students/$studentId/quran-assignment');
      return StudentQuranAssignment.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل خطة التسميع');
    }
  }

  Future<ParentPlanOverview> getPlanOverview(String studentId) async {
    try {
      final response =
          await _dio.get('/api/students/$studentId/plan-overview');
      return ParentPlanOverview.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل ملخص الخطة');
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

  Future<PagedResult<ParentPlanRow>> getPlanRows(
    String studentId, {
    required String planType,
    required int page,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/students/$studentId/plan-rows',
        queryParameters: {
          'planType': planType,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        ParentPlanRow.fromJson,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل صفوف الخطة');
    }
  }
}
