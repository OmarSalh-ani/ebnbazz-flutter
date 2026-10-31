import '../../../core/constants/app_constants.dart';

class PublicHomeConstants {
  PublicHomeConstants._();

  static const int previewContentLimit = 3;
  static const int previewLibraryLimit = 5;

  static const String websiteBase = 'https://ebnbazz.com';
  static const String registrationMen = '$websiteBase/registration?q=mregister';
  static const String registrationWomen =
      '$websiteBase/registration?q=wregister';
  static const String adviceListing = '$websiteBase/advice';

  static const String heroTagline =
      'نسعى لنشر العلم الشرعي والقيم الإسلامية في المجتمع من خلال برامج تعليمية متميزة وأنشطة اجتماعية مؤثرة';

  static const String defaultMasgedName = AppConstants.appNameFull;

  static const accentGold = 0xFFD4AF37;
}

class PublicSectionMeta {
  const PublicSectionMeta({
    required this.badge,
    required this.title,
    required this.subtitle,
    this.viewAllLabel,
  });

  final String badge;
  final String title;
  final String subtitle;
  final String? viewAllLabel;

  static const sheikhTestimonials = PublicSectionMeta(
    badge: 'التزكيات',
    title: 'تزكيات الشيوخ الكرام',
    subtitle: 'ماذا قال عنا مشايخنا الكرام',
  );

  static const advice = PublicSectionMeta(
    badge: 'النصائح',
    title: 'نصائح وإرشادات',
    subtitle: 'اطّلع على نصائحنا المفيدة وإرشاداتنا المتنوعة',
    viewAllLabel: 'كل النصائح',
  );

  static const centerReleases = PublicSectionMeta(
    badge: 'إصداراتنا',
    title: 'إصدارات المركز',
    subtitle: 'تصفح أحدث إصدارات المركز وحمّل الملفات بسهولة',
    viewAllLabel: 'كل الإصدارات',
  );

  static const sharhs = PublicSectionMeta(
    badge: 'الشروحات',
    title: 'الشروحات',
    subtitle: 'تصفح شروحات المركز وحمّل الملفات بسهولة',
    viewAllLabel: 'كل الشروحات',
  );

  static const manzumas = PublicSectionMeta(
    badge: 'المنظومات',
    title: 'المنظومات',
    subtitle: 'تصفح منظومات المركز وحمّل الملفات بسهولة',
    viewAllLabel: 'كل المنظومات',
  );

  static const news = PublicSectionMeta(
    badge: 'الأخبار',
    title: 'آخر المستجدات',
    subtitle: 'تابع آخر أخبار المركز وفعالياته',
    viewAllLabel: 'كل الأخبار',
  );

  static const activities = PublicSectionMeta(
    badge: 'الأنشطة',
    title: 'برامجنا وأنشطتنا',
    subtitle: 'تعرّف على برامجنا التعليمية وأنشطتنا المجتمعية',
    viewAllLabel: 'كل الأنشطة',
  );
}
