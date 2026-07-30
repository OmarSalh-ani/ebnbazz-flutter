import '../../../core/utils/media_url_helper.dart';

class NewsModel {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final DateTime date;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.date,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      content: json['description'] as String? ?? '',
      imageUrl: MediaUrlHelper.resolve(json['imageUrl'] as String?) ?? '',
      date: json['newsDate'] != null
          ? DateTime.parse(json['newsDate'].toString())
          : DateTime.now(),
    );
  }
}
