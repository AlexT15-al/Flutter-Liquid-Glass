import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/route.dart';

/// Whether a workout can be followed by GPS.
enum LocationAccess { granted, denied, serviceOff }

/// The phone's GPS, as a stream of route points for a workout.
///
/// On Android, fixes keep coming with the screen off because the workout
/// runs a foreground service of type location (see `WorkoutService`), whose
/// notification is the live workout itself. On iOS it asks for background
/// updates, which shows the blue location pill while a workout records.
class LocationTracker {
  const LocationTracker();

  /// Asks for location. From a button the user pressed: Start.
  Future<LocationAccess> ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return LocationAccess.denied;
    }
    return LocationAccess.granted;
  }

  /// Fixes as they arrive, filtered to the ones good enough to draw a route
  /// with.
  Stream<RoutePoint> watch() {
    return Geolocator.getPositionStream(locationSettings: _settings())
        .where((p) => p.accuracy <= maxAccuracyM)
        .map(
          (p) => RoutePoint(
            latitude: p.latitude,
            longitude: p.longitude,
            altitude: p.altitude == 0 ? null : p.altitude,
            accuracy: p.accuracy,
            time: p.timestamp,
          ),
        );
  }

  /// Fixes vaguer than this are dropped: a 50 m circle would draw zigzags
  /// across the street and add distance nobody ran.
  static const double maxAccuracyM = 30;

  static LocationSettings _settings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
          intervalDuration: const Duration(seconds: 1),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
          activityType: ActivityType.fitness,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
        );
    }
  }
}
