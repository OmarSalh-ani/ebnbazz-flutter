import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

const _appBuildId = String.fromEnvironment('APP_BUILD_ID', defaultValue: 'dev');
const _storageKey = 'parent-app-build-id';
const _checkInterval = Duration(minutes: 5);

Future<String?> _fetchLatestBuildId() async {
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final request = await html.HttpRequest.request(
      'version.json?_=$timestamp',
      method: 'GET',
      requestHeaders: {'Cache-Control': 'no-cache'},
    );
    if (request.status != 200 || request.responseText == null) {
      return null;
    }

    final payload = jsonDecode(request.responseText!) as Map<String, dynamic>;
    final version = payload['version'];
    return version is String && version.isNotEmpty ? version : null;
  } catch (_) {
    return null;
  }
}

void _rememberBuildId(String buildId) {
  html.window.sessionStorage[_storageKey] = buildId;
}

void _reloadForUpdate() {
  final url = html.window.location.href;
  final separator = url.contains('?') ? '&' : '?';
  html.window.location.replace('$url${separator}_v=${DateTime.now().millisecondsSinceEpoch}');
}

Future<void> checkForWebAppUpdate() async {
  if (_appBuildId == 'dev') return;

  final latestBuildId = await _fetchLatestBuildId();
  if (latestBuildId == null) return;

  final storedBuildId = html.window.sessionStorage[_storageKey];

  if (storedBuildId == null || storedBuildId.isEmpty) {
    if (_appBuildId != latestBuildId) {
      _rememberBuildId(latestBuildId);
      _reloadForUpdate();
      return;
    }

    _rememberBuildId(latestBuildId);
    return;
  }

  if (storedBuildId != latestBuildId || _appBuildId != latestBuildId) {
    _rememberBuildId(latestBuildId);
    _reloadForUpdate();
  }
}

void startWebAppUpdateWatcher() {
  if (_appBuildId == 'dev') return;

  unawaited(checkForWebAppUpdate());

  html.window.onFocus.listen((_) {
    unawaited(checkForWebAppUpdate());
  });

  html.document.onVisibilityChange.listen((_) {
    if (html.document.visibilityState == 'visible') {
      unawaited(checkForWebAppUpdate());
    }
  });

  Timer.periodic(_checkInterval, (_) {
    unawaited(checkForWebAppUpdate());
  });
}
