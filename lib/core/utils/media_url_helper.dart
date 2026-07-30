import '../constants/app_constants.dart';

/// Resolves DB media paths (e.g. ~/uploads/photo.jpg) to full URLs.
class MediaUrlHelper {
  MediaUrlHelper._();

  static const _legacyMediaHosts = {
    'ebnbazz.com',
    'www.ebnbazz.com',
  };

  static String? resolve(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _rewriteLegacyHost(trimmed);
    }

    var relative = trimmed.replaceAll('\\', '/');
    if (relative.startsWith('~/')) {
      relative = relative.substring(2);
    } else if (relative.startsWith('~')) {
      relative = relative.substring(1);
    }
    if (relative.startsWith('/')) {
      relative = relative.substring(1);
    }

    final base = AppConstants.mediaBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/$relative';
  }

  static String _rewriteLegacyHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    if (!_legacyMediaHosts.contains(uri.host.toLowerCase())) return url;

    final base = AppConstants.mediaBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = uri.hasEmptyPath ? '' : uri.path;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '$base$path$query';
  }
}
