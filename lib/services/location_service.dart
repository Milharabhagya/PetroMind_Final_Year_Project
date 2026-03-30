import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  static double distanceKm(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    final meters =
        Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return meters / 1000;
  }
}