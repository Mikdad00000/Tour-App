import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/expense/domain/expense.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<GeoPoint2?> tryGetCurrent() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final asked = await Geolocator.requestPermission();
        if (asked == LocationPermission.denied || asked == LocationPermission.deniedForever) {
          return null;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      String? place;
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final m = marks.first;
          place = [m.name, m.subLocality, m.locality]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
        }
      } catch (_) {/* offline geocode unavailable */}
      return GeoPoint2(pos.latitude, pos.longitude, place);
    } catch (_) {
      return null;
    }
  }
}
