import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<({double latitude, double longitude})> getCurrentCoordinates() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('يرجى تفعيل خدمة الموقع على الجهاز');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationServiceException('يجب السماح بالوصول إلى الموقع لتسجيل الحضور');
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'إذن الموقع مرفوض. يرجى تفعيله من إعدادات التطبيق',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      throw LocationServiceException('تعذر تحديد الموقع الحالي');
    }
  }
}
