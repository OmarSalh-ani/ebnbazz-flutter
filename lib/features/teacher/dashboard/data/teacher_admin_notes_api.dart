import 'package:masged_parent_app/teacher_core/network/api_client.dart';



class TeacherAdminNoteItem {

  TeacherAdminNoteItem({

    required this.id,

    required this.note,

    required this.createdAt,

    required this.createdAtFormatted,

    required this.isRead,

    this.readTime,

    this.readTimeFormatted,

  });



  final int id;

  final String note;

  final DateTime createdAt;

  final String createdAtFormatted;

  final bool isRead;

  final DateTime? readTime;

  final String? readTimeFormatted;



  factory TeacherAdminNoteItem.fromJson(Map<String, dynamic> json) {

    final createdAt = DateTime.parse(json['createdAt'].toString()).toLocal();

    final formatted = (json['createdAtFormatted'] ?? '').toString().trim();

    final readTimeRaw = json['readTime'];

    final readTime = readTimeRaw == null

        ? null

        : DateTime.tryParse(readTimeRaw.toString())?.toLocal();

    final readFormatted =

        (json['readTimeFormatted'] ?? '').toString().trim();



    return TeacherAdminNoteItem(

      id: json['id'] as int? ?? 0,

      note: (json['note'] ?? '').toString(),

      createdAt: createdAt,

      createdAtFormatted: formatted.isNotEmpty

          ? formatted

          : _formatDateTime(createdAt),

      isRead: json['isRead'] as bool? ?? false,

      readTime: readTime,

      readTimeFormatted:

          readFormatted.isNotEmpty ? readFormatted : null,

    );

  }



  static String _formatDateTime(DateTime value) {

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;

    final minute = value.minute.toString().padLeft(2, '0');

    final period = value.hour >= 12 ? 'PM' : 'AM';

    final day = value.day.toString().padLeft(2, '0');

    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year} $hour:$minute $period';

  }

}



class TeacherAdminNotesApi {

  TeacherAdminNotesApi(this._client);



  final TeacherApiClient _client;



  Future<List<TeacherAdminNoteItem>> fetchAll() {

    return _client.get<List<TeacherAdminNoteItem>>(

      '/api/TeacherAdminNotes',

      parseData: (json) {

        final list = json as List<dynamic>;

        return list

            .map(

              (e) => TeacherAdminNoteItem.fromJson(

                Map<String, dynamic>.from(e as Map),

              ),

            )

            .toList();

      },

    );

  }



  Future<void> markAllRead() {

    return _client.postVoid(

      '/api/TeacherAdminNotes/mark-read',

      body: const {},

    );

  }

}

