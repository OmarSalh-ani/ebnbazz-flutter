import 'package:masged_parent_app/app/models/app_role.dart';
import 'package:masged_parent_app/teacher_core/network/api_client.dart';
import 'package:masged_parent_app/features/chat/models/chat_message_model.dart';
import '../models/parent_chat_thread_vm.dart';

class TeacherChatApi {
  TeacherChatApi(this._client);

  final TeacherApiClient _client;

  Future<List<ParentChatThreadVm>> getConversations() {
    return _client.get<List<ParentChatThreadVm>>(
      '/api/chat/conversations',
      parseData: (json) {
        final list = json as List<dynamic>;
        return list
            .map((e) => ParentChatThreadVm.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<ChatMessage>> getMessages({
    required int studentId,
    required int teacherId,
    int? beforeMessageId,
    int take = 50,
  }) {
    return _client.get<List<ChatMessage>>(
      '/api/chat/students/$studentId/messages',
      queryParameters: {
        'teacherId': teacherId,
        if (beforeMessageId != null) 'beforeId': beforeMessageId,
        'take': take,
      },
      parseData: (json) {
        final list = json as List<dynamic>;
        return list
            .map(
              (e) => ChatMessage.fromApiJson(
                e as Map<String, dynamic>,
                viewerRole: AppRole.teacher,
              ),
            )
            .toList();
      },
    );
  }

  Future<ChatMessage> sendMessageRest({
    required int studentId,
    required int teacherId,
    required String text,
  }) {
    return _client.post<ChatMessage>(
      '/api/chat/students/$studentId/messages?teacherId=$teacherId',
      body: {
        'messageText': text,
        'studentId': studentId,
      },
      parseData: (json) => ChatMessage.fromApiJson(
        Map<String, dynamic>.from(json as Map),
        viewerRole: AppRole.teacher,
      ),
    );
  }

  Future<void> markReadRest({
    required int studentId,
    required int teacherId,
  }) {
    return _client.postVoid(
      '/api/chat/students/$studentId/mark-read?teacherId=$teacherId',
      body: {},
    );
  }
}
