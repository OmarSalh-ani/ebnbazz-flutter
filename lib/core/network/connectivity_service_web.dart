import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Web connectivity — avoids dart:io DNS lookups that fail or stall in browsers.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    return !_hasNoNetwork(results);
  }

  Stream<bool> get onInternetStatusChanged async* {
    yield await hasInternetConnection();

    await for (final results in _connectivity.onConnectivityChanged) {
      yield !_hasNoNetwork(results);
    }
  }

  bool _hasNoNetwork(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
  }
}
