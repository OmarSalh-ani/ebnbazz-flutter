import '../constants/app_constants.dart';

/// Single-host API configuration for the unified Masged mobile app.
class UnifiedApiConfig {
  UnifiedApiConfig._();

  /// Parent and teacher share one API host (MasgedParentMobileAPI).
  static String get apiHost => AppConstants.apiBaseUrl;

  static String get parentBaseUrl => apiHost;

  static String get teacherBaseUrl => apiHost;

  /// Rewrites `/api/...` teacher paths to `/api/teacher/...` on the unified host.
  static String teacherPath(String path) {
    if (path.startsWith('/api/teacher/')) return path;
    if (path.startsWith('/api/')) {
      return '/api/teacher${path.substring(4)}';
    }
    return path;
  }
}
