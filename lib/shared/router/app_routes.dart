class AppRoutes {
  static const splash = '/';
  static const productIntro = '/intro';
  static const permissionAsk = '/permission-ask';
  static const teacherDashboard = '/teacher/dashboard';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp/:phone';
  static const home = '/home';
  static const children = '/children';
  static const schedule = '/schedule';
  static const attendance = '/attendance';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const services = '/services';
  static const addChild = '/add-child';
  static const quran = '/quran/:childId';
  static const childProfile = '/child-profile/:childId';
  static const chatTeachers = '/chat-teachers';
  static const chatDetail = '/chat-detail/:teacherId/:studentId';
  static const ziker = '/ziker/:name';
  static const zikerStats = '/ziker-stats';
  static const holyQuran = '/holy-quran';
  static const library = '/library';
  static const libraryPdf = '/library-pdf';
  static const surahDetail = '/surah-detail/:surahNumber';
  static const masgedNews = '/masged-news';
  static const newsDetails = '/news-details/:newsId';
  static const adhkar = '/adhkar';
  static const adhkarGroup = '/adhkar/group/:groupId';
  static const adhkarCategory = '/adhkar/category/:categoryId';

  // Helpers to build concrete paths with params
  static String otpPath(String phone) => '/otp/$phone';
  static String quranPath(String childId) => '/quran/$childId';
  static String childProfilePath(String childId) => '/child-profile/$childId';
  static String chatDetailPath(String teacherId, String studentId) =>
      '/chat-detail/$teacherId/$studentId';
  static String zikerPath(String name) =>
      '/ziker/${Uri.encodeComponent(name)}';
  static String surahDetailPath(int surahNumber) =>
      '/surah-detail/$surahNumber';
  static String newsDetailsPath(String newsId) => '/news-details/$newsId';
  static String adhkarGroupPath(String groupId) => '/adhkar/group/$groupId';
  static String adhkarCategoryPath(int categoryId, {required String session}) =>
      '/adhkar/category/$categoryId?session=${Uri.encodeComponent(session)}';

  /// Routes that work without an internet connection.
  static const offlineAllowedPaths = [
    splash,
    productIntro,
    permissionAsk,
    login,
    register,
    services,
    zikerStats,
    holyQuran,
    adhkar,
    teacherDashboard,
  ];

  static bool isOfflineAllowed(String location) {
    if (offlineAllowedPaths.any((path) => location.startsWith(path))) {
      return true;
    }
    if (location.startsWith(ziker)) return true;
    if (location.startsWith(surahDetail)) return true;
    if (location.startsWith('/otp/')) return true;
    if (location.startsWith(adhkar)) return true;
    return false;
  }
}
