import '../../../core/utils/media_url_helper.dart';
import '../../library/models/center_release_model.dart';
import '../../home/models/news_model.dart';

class HeroSlide {
  HeroSlide({required this.id, required this.imageUrl});

  final int id;
  final String imageUrl;

  factory HeroSlide.fromJson(Map<String, dynamic> json) {
    return HeroSlide(
      id: _int(json['id']),
      imageUrl: MediaUrlHelper.resolve(json['imageUrl'] as String?) ?? '',
    );
  }
}

class AdviceItem {
  AdviceItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.linkUrl,
  });

  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? linkUrl;

  factory AdviceItem.fromJson(Map<String, dynamic> json) {
    return AdviceItem(
      id: _int(json['id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: MediaUrlHelper.resolve(json['imageUrl'] as String?),
      linkUrl: json['linkUrl'] as String?,
    );
  }
}

class SheikhTestimonial {
  SheikhTestimonial({
    required this.id,
    required this.name,
    required this.rank,
    required this.quote,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String rank;
  final String quote;
  final String? imageUrl;

  factory SheikhTestimonial.fromJson(Map<String, dynamic> json) {
    return SheikhTestimonial(
      id: _int(json['id']),
      name: json['name'] as String? ?? '',
      rank: json['rank'] as String? ?? '',
      quote: json['quote'] as String? ?? '',
      imageUrl: MediaUrlHelper.resolve(json['imageUrl'] as String?),
    );
  }
}

class PublicLibraryItem {
  PublicLibraryItem({
    required this.id,
    required this.title,
    required this.downloadLink,
    this.thumbnailImage,
    this.youtubeUrl,
    required this.uploadedAt,
  });

  final int id;
  final String title;
  final String downloadLink;
  final String? thumbnailImage;
  final String? youtubeUrl;
  final DateTime uploadedAt;

  bool get hasYoutubeUrl => (youtubeUrl ?? '').trim().isNotEmpty;

  factory PublicLibraryItem.fromJson(Map<String, dynamic> json) {
    return PublicLibraryItem(
      id: _int(json['id']),
      title: json['title'] as String? ?? '',
      downloadLink:
          MediaUrlHelper.resolve(json['downloadLink'] as String?) ??
              (json['downloadLink'] as String? ?? ''),
      thumbnailImage:
          MediaUrlHelper.resolve(json['thumbnailImage'] as String?),
      youtubeUrl: json['youtubeUrl'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CenterReleaseModel toCenterReleaseModel() {
    return CenterReleaseModel(
      id: id,
      title: title,
      downloadLink: downloadLink,
      thumbnailImage: thumbnailImage ?? '',
      youtubeUrl: youtubeUrl ?? '',
      uploadedAt: uploadedAt,
    );
  }
}

class PublicNewsItem {
  PublicNewsItem({
    required this.id,
    required this.title,
    this.description,
    required this.newsDate,
    this.imageUrl,
    this.linkUrl,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime newsDate;
  final String? imageUrl;
  final String? linkUrl;

  factory PublicNewsItem.fromJson(Map<String, dynamic> json) {
    return PublicNewsItem(
      id: _int(json['id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      newsDate: json['newsDate'] != null
          ? DateTime.tryParse(json['newsDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      imageUrl: MediaUrlHelper.resolve(json['imageUrl'] as String?),
      linkUrl: json['linkUrl'] as String?,
    );
  }

  NewsModel toNewsModel() {
    return NewsModel(
      id: id.toString(),
      title: title,
      content: description ?? '',
      imageUrl: imageUrl ?? '',
      date: newsDate,
    );
  }
}

class ActivityItem {
  ActivityItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.iconClass,
  });

  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? iconClass;

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: _int(json['id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: MediaUrlHelper.resolve(json['imageUrl'] as String?),
      iconClass: json['iconClass'] as String?,
    );
  }
}

class AboutInfo {
  AboutInfo({required this.content, this.address, this.mapsUrl});

  final String content;
  final String? address;
  final String? mapsUrl;

  factory AboutInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AboutInfo(content: '');
    }
    return AboutInfo(
      content: json['content'] as String? ?? '',
      address: json['address'] as String?,
      mapsUrl: json['mapsUrl'] as String?,
    );
  }
}

class SocialLink {
  SocialLink({
    required this.id,
    required this.platformName,
    required this.url,
    this.iconClass,
    required this.resolvedIconClass,
  });

  final int id;
  final String platformName;
  final String url;
  final String? iconClass;
  final String resolvedIconClass;

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      id: _int(json['id']),
      platformName: json['platformName'] as String? ?? '',
      url: json['url'] as String? ?? '',
      iconClass: json['iconClass'] as String?,
      resolvedIconClass: json['resolvedIconClass'] as String? ?? '',
    );
  }
}

class PublicWebsiteContent {
  PublicWebsiteContent({
    required this.heroSlides,
    required this.advice,
    required this.sheikhTestimonials,
    required this.centerReleases,
    required this.sharhs,
    required this.manzumas,
    required this.news,
    required this.activities,
    required this.about,
    required this.socialLinks,
  });

  final List<HeroSlide> heroSlides;
  final List<AdviceItem> advice;
  final List<SheikhTestimonial> sheikhTestimonials;
  final List<PublicLibraryItem> centerReleases;
  final List<PublicLibraryItem> sharhs;
  final List<PublicLibraryItem> manzumas;
  final List<PublicNewsItem> news;
  final List<ActivityItem> activities;
  final AboutInfo about;
  final List<SocialLink> socialLinks;

  factory PublicWebsiteContent.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = json[key];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final competitions = mapList('competitions', AdviceItem.fromJson);
    final adviceRaw = mapList('advice', AdviceItem.fromJson);

    return PublicWebsiteContent(
      heroSlides: mapList('heroSlides', HeroSlide.fromJson),
      advice: adviceRaw.isNotEmpty ? adviceRaw : competitions,
      sheikhTestimonials:
          mapList('sheikhTestimonials', SheikhTestimonial.fromJson),
      centerReleases: mapList('centerReleases', PublicLibraryItem.fromJson),
      sharhs: mapList('sharhs', PublicLibraryItem.fromJson),
      manzumas: mapList('manzumas', PublicLibraryItem.fromJson),
      news: mapList('news', PublicNewsItem.fromJson),
      activities: mapList('activities', ActivityItem.fromJson),
      about: AboutInfo.fromJson(
        json['about'] is Map
            ? Map<String, dynamic>.from(json['about'] as Map)
            : null,
      ),
      socialLinks: mapList('socialLinks', SocialLink.fromJson),
    );
  }
}

class RegistrationFormLabels {
  RegistrationFormLabels({
    required this.showActivitiesSection,
    required this.showActivitiesNav,
  });

  final bool showActivitiesSection;
  final bool showActivitiesNav;

  factory RegistrationFormLabels.fromJson(Map<String, dynamic>? json) {
    return RegistrationFormLabels(
      showActivitiesSection: json?['showActivitiesSection'] as bool? ?? false,
      showActivitiesNav: json?['showActivitiesNav'] as bool? ?? false,
    );
  }
}

class RegistrationConfig {
  RegistrationConfig({
    required this.registrationEnabled,
    required this.labels,
  });

  final bool registrationEnabled;
  final RegistrationFormLabels labels;

  factory RegistrationConfig.fromJson(Map<String, dynamic> json) {
    final labelsJson = json['labels'];
    return RegistrationConfig(
      registrationEnabled: json['registrationEnabled'] as bool? ?? false,
      labels: RegistrationFormLabels.fromJson(
        labelsJson is Map
            ? Map<String, dynamic>.from(labelsJson)
            : null,
      ),
    );
  }
}

class PublicRegistrationContext {
  const PublicRegistrationContext({
    required this.menEnabled,
    required this.womenEnabled,
    required this.labels,
  });

  final bool menEnabled;
  final bool womenEnabled;
  final RegistrationFormLabels labels;
}

class MasgedBranding {
  MasgedBranding({
    required this.masgedName,
    this.logoUrl,
    this.parentAppStoreUrl,
    this.parentGooglePlayUrl,
  });

  final String masgedName;
  final String? logoUrl;
  final String? parentAppStoreUrl;
  final String? parentGooglePlayUrl;

  factory MasgedBranding.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MasgedBranding(masgedName: '');
    }
    return MasgedBranding(
      masgedName: json['masgedName'] as String? ?? '',
      logoUrl: MediaUrlHelper.resolve(json['logoUrl'] as String?),
      parentAppStoreUrl: json['parentAppStoreUrl'] as String?,
      parentGooglePlayUrl: json['parentGooglePlayUrl'] as String?,
    );
  }
}

class PublicHomeData {
  const PublicHomeData({
    required this.content,
    required this.registration,
    required this.branding,
  });

  final PublicWebsiteContent content;
  final PublicRegistrationContext registration;
  final MasgedBranding branding;
}

int _int(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}
