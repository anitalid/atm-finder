import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Haversine;
import '../core/constants.dart';

class LocationService {
  static Future<LatLng> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return _fallback(); // FIXED
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return _fallback();
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) { return _fallback(); }
  }
  static LatLng _fallback() => const LatLng(AppConstants.fallbackLat, AppConstants.fallbackLng);
}