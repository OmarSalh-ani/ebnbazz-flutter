import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';

/// Loads QCF page fonts on demand from CDN cache (mobile) or bundled assets (web).
class QcfFontLoader {
  QcfFontLoader._();

  static const _maxCachedPages = 16;

  static final _loadedPages = <int>{};
  static final _loadOrder = <int>[];
  static final _inFlight = <int, Future<void>>{};

  static String familyForPage(int pageIndex) {
    return 'QCF_P${pageIndex.toString().padLeft(3, '0')}';
  }

  static String assetPathForPage(int pageIndex) {
    return 'assets/fonts/v2woff/p$pageIndex.woff';
  }

  static String remoteUrlForPage(int pageIndex) {
    return '${AppConstants.qcfFontBaseUrl}/p$pageIndex.woff';
  }

  static Future<void> ensurePageLoaded(int pageIndex) async {
    if (pageIndex < 1 || pageIndex > 604) return;

    if (_loadedPages.contains(pageIndex)) {
      _touch(pageIndex);
      return;
    }

    final existing = _inFlight[pageIndex];
    if (existing != null) {
      await existing;
      return;
    }

    final load = _loadPage(pageIndex);
    _inFlight[pageIndex] = load;
    try {
      await load;
    } finally {
      _inFlight.remove(pageIndex);
    }
  }

  static Future<void> ensurePagesLoaded(Iterable<int> pageIndexes) async {
    await Future.wait(pageIndexes.map(ensurePageLoaded));
  }

  static Future<void> _loadPage(int pageIndex) async {
    if (_loadedPages.contains(pageIndex)) return;

    final family = familyForPage(pageIndex);
    final bytes = await _resolveFontBytes(pageIndex);

    final loader = FontLoader(family);
    loader.addFont(Future.value(bytes));
    await loader.load();

    _loadedPages.add(pageIndex);
    _touch(pageIndex);
    _evictOverflow();
  }

  static Future<ByteData> _resolveFontBytes(int pageIndex) async {
    if (!kIsWeb) {
      final cached = await _readCacheFile(pageIndex);
      if (cached != null) return cached;
    }

    if (AppConstants.bundleQcfFonts || kIsWeb) {
      try {
        return await rootBundle.load(assetPathForPage(pageIndex));
      } catch (_) {
        if (kIsWeb) rethrow;
      }
    }

    if (kIsWeb) {
      throw StateError('QCF font p$pageIndex not found in bundle');
    }

    return _downloadAndCache(pageIndex);
  }

  static Future<File> _cacheFileFor(int pageIndex) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/qcf_fonts/p$pageIndex.woff');
  }

  static Future<ByteData?> _readCacheFile(int pageIndex) async {
    try {
      final file = await _cacheFileFor(pageIndex);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    } catch (e) {
      debugPrint('QcfFontLoader: cache read failed for p$pageIndex: $e');
      return null;
    }
  }

  static Future<ByteData> _downloadAndCache(int pageIndex) async {
    final url = remoteUrlForPage(pageIndex);
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw StateError('Empty QCF font response for p$pageIndex');
      }

      final file = await _cacheFileFor(pageIndex);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data, flush: true);

      return ByteData.view(Uint8List.fromList(data).buffer);
    } catch (error, stackTrace) {
      debugPrint('QcfFontLoader: download failed $url: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  static void _touch(int pageIndex) {
    _loadOrder.remove(pageIndex);
    _loadOrder.add(pageIndex);
  }

  static void _evictOverflow() {
    while (_loadOrder.length > _maxCachedPages) {
      final evicted = _loadOrder.removeAt(0);
      _loadedPages.remove(evicted);
    }
  }
}
