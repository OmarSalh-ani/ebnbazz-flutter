import '../../../core/utils/media_url_helper.dart';

class CenterReleaseModel {
  final int id;
  final String title;
  final String downloadLink;
  final String thumbnailImage;
  final DateTime uploadedAt;

  CenterReleaseModel({
    required this.id,
    required this.title,
    required this.downloadLink,
    required this.thumbnailImage,
    required this.uploadedAt,
  });

  factory CenterReleaseModel.fromJson(Map<String, dynamic> json) {
    return CenterReleaseModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] as String? ?? '',
      downloadLink:
          MediaUrlHelper.resolve(json['downloadLink'] as String?) ??
              (json['downloadLink'] as String? ?? ''),
      thumbnailImage:
          MediaUrlHelper.resolve(json['thumbnailImage'] as String?) ??
              (json['thumbnailImage'] as String? ?? ''),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'].toString())
          : DateTime.now(),
    );
  }
}
