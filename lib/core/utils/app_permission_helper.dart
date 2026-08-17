import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/auth/models/app_permission_item.dart';

/// Cross-platform permission checks/requests for onboarding.
///
/// On web, [permission_handler] does not implement location status checks;
/// Geolocator is used for location instead.
class AppPermissionHelper {
  AppPermissionHelper._();

  static Future<PermissionStatus> statusFor(AppPermissionItem item) async {
    if (item.permission == null) return PermissionStatus.denied;

    if (kIsWeb && item.id == 'location') {
      return _fromGeolocator(await Geolocator.checkPermission());
    }

    try {
      return await item.permission!.status;
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  /// Requests the system permission dialog when it can still be shown.
  ///
  /// Never opens Settings. If the user already denied the system prompt,
  /// returns the current status so the caller can explain and optionally
  /// offer a Settings link.
  static Future<PermissionStatus> requestFor(AppPermissionItem item) async {
    if (item.permission == null) return PermissionStatus.denied;

    if (kIsWeb && item.id == 'location') {
      return _fromGeolocator(await Geolocator.requestPermission());
    }

    try {
      return await requestRuntime(item.permission!);
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  static Future<PermissionStatus> requestRuntime(Permission permission) async {
    final current = await permission.status;
    if (current.isGranted || current.isLimited) return current;
    if (current.isPermanentlyDenied || current.isRestricted) return current;
    return permission.request();
  }

  static bool canUse(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  static bool needsSettings(PermissionStatus status) =>
      status.isPermanentlyDenied || status.isRestricted;

  static PermissionStatus _fromGeolocator(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return PermissionStatus.granted;
      case LocationPermission.deniedForever:
        return PermissionStatus.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return PermissionStatus.denied;
    }
  }
}
