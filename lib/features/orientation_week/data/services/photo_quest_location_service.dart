import 'package:geolocator/geolocator.dart';

/// GPS snapshot collected at Photo Quest capture time for the CV verify service.
class PhotoQuestCaptureLocation {
  const PhotoQuestCaptureLocation({
    required this.lat,
    required this.lon,
    required this.accuracyM,
    required this.isMocked,
  });

  final double lat;
  final double lon;
  final double accuracyM;
  final bool isMocked;
}

/// Best-effort location for a Photo Quest submission.
///
/// Returns `null` when the student denies permission or GPS is unavailable —
/// the backend still accepts the photo; CV simply skips geofence / sunset-geo
/// checks when coordinates are missing.
class PhotoQuestLocationService {
  const PhotoQuestLocationService();

  Future<PhotoQuestCaptureLocation?> current() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      return PhotoQuestCaptureLocation(
        lat: position.latitude,
        lon: position.longitude,
        accuracyM: position.accuracy,
        isMocked: position.isMocked,
      );
    } catch (_) {
      return null;
    }
  }
}
