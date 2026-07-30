import 'package:dio/dio.dart';

import 'package:masged_parent_app/app/models/app_role.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/chat_conversation_vm.dart';
import '../models/chat_message_model.dart';

class ChatApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ChatConversationVm>> getConversations() async {
    try {
      final response = await _dio.get('/api/chat/conversations');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ChatConversationVm.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل المحادثات');
    }
  }

  Future<List<ChatMessage>> getMessages({
    required int teacherId,
    required int studentId,
    int? beforeMessageId,
    int take = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/chat/teachers/$teacherId/students/$studentId/messages',
        queryParameters: {
          if (beforeMessageId != null) 'beforeId': beforeMessageId,
          'take': take,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              ChatMessage.fromApiJson(e as Map<String, dynamic>, viewerRole: AppRole.parent))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر تحميل الرسائل');
    }
  }

  Future<void> sendMessageRest({
    required int teacherId,
    required int studentId,
    required String text,
  }) async {
    try {
      await _dio.post(
        '/api/chat/teachers/$teacherId/students/$studentId/messages',
        data: {
          'messageText': text,
          'studentId': studentId,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('تعذر إرسال الرسالة');
    }
  }

  Future<void> markReadRest({
    required int teacherId,
    required int studentId,
  }) async {
    try {
      await _dio.post(
        '/api/chat/teachers/$teacherId/students/$studentId/mark-read',
        data: {},
      );
    } catch (_) {
      /* best-effort */
    }
  }
}
