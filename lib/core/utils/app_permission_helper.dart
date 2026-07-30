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

  static Future<PermissionStatus> requestFor(AppPermissionItem item) async {
    if (item.permission == null) return PermissionStatus.denied;

    if (kIsWeb && item.id == 'location') {
      return _fromGeolocator(await Geolocator.requestPermission());
    }

    try {
      return await item.permission!.request();
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

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
