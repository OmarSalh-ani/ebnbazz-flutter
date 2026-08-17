class AppConstants {
  AppConstants._();

  static const String appName = 'مركز ابن باز';
  static const String appNameFull = 'مركز الامام عبد العزيز بن باز للعلوم الشرعية ';
  static const String appSubtitle = 'بإشراف مركز الامام عبد العزيز بن باز للعلوم الشرعية';

  // Kuwait dial code
  static const String defaultDialCode = '+965';
  static const String defaultCountryCode = 'KW';

  // API — single source of truth for HTTP + SignalR hubs (MasgedParentMobileAPI).
  // REST routes use `/api/...`; hubs use `/hubs/...` on the same host.
  // Temporary: production API in debug too. To restore local:
  // return kDebugMode ? 'http://localhost:5100' : _apiBaseUrlProduction;
  // Override: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5100
  static const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');
  static const String _apiBaseUrlProduction =
      'https://teachermobileapi.ebnbazz.com';

  static String get apiBaseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) return _apiBaseUrlFromEnv;
    return _apiBaseUrlProduction;
  }

  /// Parent Mobile API SignalR hub (JWT via access_token factory).
  static const String chatHubPath = '/hubs/chat';
  static const String videoCallHubPath = '/hubs/video-call';

  // Media files (PhotoPath, news images) — served by AdminAPI static /uploads/*
  // Production: https://admin-api.ebnbazz.com
  // Local override: flutter run --dart-define=MEDIA_BASE_URL=http://10.0.2.2:5000
  static const String mediaBaseUrl = String.fromEnvironment(
    'MEDIA_BASE_URL',
    defaultValue: 'https://admin-api.ebnbazz.com',
  );

  /// Hosted privacy policy — required in Play Console and in-app (Settings / Login).
  /// Override at build time: --dart-define=PRIVACY_POLICY_URL=https://example.com/privacy
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://ebnbazz.com/privacy-policy',
  );

  static bool get hasPrivacyPolicyUrl => privacyPolicyUrl.trim().isNotEmpty;

  /// QCF Quran page fonts (~103 MB). Downloaded on first use, not bundled in release.
  /// Host files at `{qcfFontBaseUrl}/p1.woff` … `p604.woff` (see tool/upload_qcf_fonts.ps1).
  static const String qcfFontBaseUrl = String.fromEnvironment(
    'QCF_FONT_BASE_URL',
    defaultValue: 'https://admin-api.ebnbazz.com/static/qcf-fonts',
  );

  /// Set true for local dev when v2woff is listed under flutter.assets.
  static const bool bundleQcfFonts = bool.fromEnvironment(
    'BUNDLE_QCF_FONTS',
    defaultValue: false,
  );

  // Shared Preferences Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserData = 'user_data';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyPermissionsOnboardingComplete =
      'permissions_onboarding_complete';
  static const String keyProductIntroComplete = 'product_intro_complete';
  static const String keyAppLaunchCount = 'app_launch_count';
  static const String keyLastReviewPromptAt = 'last_review_prompt_at';
  static const String keyReviewPromptCount = 'review_prompt_count';

  /// Apple App Store ID for openStoreListing fallback.
  static const String appStoreId = '6786759219';

  static const int reviewPromptMinLaunches = 3;
  static const int reviewPromptCooldownDays = 90;
  static const int reviewPromptMaxCount = 3;

  // Durations
  static const int splashDuration = 2500;
  static const int otpResendSeconds = 60;

  // Days of Week
  static const List<String> daysOfWeek = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  // Nav items labels
  static const List<String> navLabels = [
    'الرئيسية',
    'أبنائي',
    'الحضور',
    'الخدمات',
    'حسابي',
  ];
}
