import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Connects to a SignalR hub, trying each transport until one succeeds.
///
/// When [HttpConnectionOptions.transport] is set to [HttpTransportType.WebSockets]
/// only, the client skips SSE and long polling with "disabled by the client".
class SignalRHubConnector {
  SignalRHubConnector._();

  static const _transports = <HttpTransportType>[
    HttpTransportType.WebSockets,
    HttpTransportType.ServerSentEvents,
    HttpTransportType.LongPolling,
  ];

  /// Long polling needs a longer HTTP timeout than the package default (2s).
  static const int _requestTimeoutMs = 60000;

  static Future<HubConnection> connect({
    required String hubUrl,
    required Future<String> Function() accessTokenFactory,
    List<int> reconnectDelays = const [1000, 3000, 7000],
  }) async {
    Object? lastError;
    StackTrace? lastStack;

    for (final transport in _transports) {
      final hub = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: accessTokenFactory,
              transport: transport,
              requestTimeout: _requestTimeoutMs,
            ),
          )
          .withAutomaticReconnect(retryDelays: reconnectDelays)
          .build();

      try {
        await hub.start();
        debugPrint('SignalR connected via $transport → $hubUrl');
        return hub;
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        debugPrint('SignalR $transport failed for $hubUrl: $e');
        try {
          await hub.stop();
        } catch (_) {}
      }
    }

    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStack ?? StackTrace.empty);
    }
    throw Exception('SignalR: all transports failed for $hubUrl');
  }
}
