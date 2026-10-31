import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/route.dart';
import '../../platform/android_permissions.dart';

/// Whether a workout can be followed by GPS.
enum LocationAccess { granted, denied, serviceOff }

/// The phone's GPS, as a stream of route points for a workout.
///
/// While it is listened to on Android it runs a foreground service with an
/// ongoing notification, which is what keeps fixes coming with the screen off
/// and the phone in a pocket. On iOS it asks for background updates, which
/// shows the blue location pill while a workout records.
class LocationTracker {
  const LocationTracker();

  /// Asks for location, and on Android 13+ for notifications too, so the
  /// recording notification is not silently hidden. From a button the user
  /// pressed: Start.
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
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Refusing notifications does not stop the recording, only hides it.
      await AndroidPermissions.request(AndroidPermissions.postNotifications);
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
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Workout in progress',
            notificationText: 'Halo is recording your route.',
            notificationChannelName: 'Workouts',
            notificationIcon: AndroidResource(name: 'ic_stat_halo'),
            setOngoing: true,
            enableWakeLock: true,
          ),
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
