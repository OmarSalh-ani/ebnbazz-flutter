import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final internetConnectionProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onInternetStatusChanged;
});

/// Global online status. Assumes online until the first connectivity check completes.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(internetConnectionProvider).maybeWhen(
        data: (isConnected) => isConnected,
        orElse: () => true,
      );
});
