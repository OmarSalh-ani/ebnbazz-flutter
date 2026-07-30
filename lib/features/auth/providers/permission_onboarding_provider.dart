import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/permission_onboarding_service.dart';

final permissionOnboardingProvider =
    StateNotifierProvider<PermissionOnboardingNotifier, AsyncValue<bool>>(
        (ref) {
  return PermissionOnboardingNotifier();
});

class PermissionOnboardingNotifier extends StateNotifier<AsyncValue<bool>> {
  PermissionOnboardingNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await PermissionOnboardingService.hasCompleted());
  }

  Future<void> markCompleted() async {
    await PermissionOnboardingService.markCompleted();
    state = const AsyncValue.data(true);
  }

  Future<void> reload() async {
    await _load();
  }
}
