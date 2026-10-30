import 'package:masged_parent_app/shared/router/app_routes.dart';

enum LibraryKind { releases, sharhs, manzumas }

class LibraryKindConfig {
  const LibraryKindConfig({
    required this.title,
    required this.emptyMessage,
    required this.loadError,
    required this.apiPath,
    required this.listRoute,
    required this.pdfRoute,
  });

  final String title;
  final String emptyMessage;
  final String loadError;
  final String apiPath;
  final String listRoute;
  final String pdfRoute;
}

const libraryKindConfigs = <LibraryKind, LibraryKindConfig>{
  LibraryKind.releases: LibraryKindConfig(
    title: 'الأصدارات',
    emptyMessage: 'لا توجد إصدارات حالياً',
    loadError: 'تعذر تحميل الأصدارات',
    apiPath: '/api/centerreleases',
    listRoute: AppRoutes.library,
    pdfRoute: AppRoutes.libraryPdf,
  ),
  LibraryKind.sharhs: LibraryKindConfig(
    title: 'الشروحات',
    emptyMessage: 'لا توجد شروحات حالياً',
    loadError: 'تعذر تحميل الشروحات',
    apiPath: '/api/sharhs',
    listRoute: AppRoutes.sharhs,
    pdfRoute: AppRoutes.sharhsPdf,
  ),
  LibraryKind.manzumas: LibraryKindConfig(
    title: 'المنظومات',
    emptyMessage: 'لا توجد منظومات حالياً',
    loadError: 'تعذر تحميل المنظومات',
    apiPath: '/api/manzumas',
    listRoute: AppRoutes.manzumas,
    pdfRoute: AppRoutes.manzumasPdf,
  ),
};
