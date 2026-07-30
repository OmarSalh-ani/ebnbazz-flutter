import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network availability and verifies actual internet access.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    if (_hasNoNetwork(results)) {
      return false;
    }
    return _verifyInternetAccess();
  }

  Stream<bool> get onInternetStatusChanged async* {
    yield await hasInternetConnection();

    await for (final results in _connectivity.onConnectivityChanged) {
      if (_hasNoNetwork(results)) {
        yield false;
        continue;
      }
      yield await _verifyInternetAccess();
    }
  }

  bool _hasNoNetwork(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
  }

  Future<bool> _verifyInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(
        const Duration(seconds: 5),
      );
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
