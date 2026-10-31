import 'dart:async';
import 'dart:math' as math;

import 'package:halo/data/location/location_tracker.dart';
import 'package:halo/domain/route.dart';

/// GPS a test drives by hand.
class FakeLocation implements LocationTracker {
  FakeLocation({this.access = LocationAccess.granted});

  final LocationAccess access;
  final StreamController<RoutePoint> _fixes = StreamController.broadcast();

  void add(RoutePoint fix) => _fixes.add(fix);

  bool get listening => _fixes.hasListener;

  @override
  Future<LocationAccess> ensureAccess() async => access;

  @override
  Stream<RoutePoint> watch() => _fixes.stream;
}

/// A loop round a park, about [km] long, as [count] fixes one after another,
/// gently rolling: something that looks like a real run on a map.
List<RoutePoint> parkLoop({
  required DateTime start,
  double km = 5.4,
  int count = 360,
  Duration every = const Duration(seconds: 5),
}) {
  const centreLat = 51.5073;
  const centreLon = -0.1657;
  const metresPerDegLat = 111195.0;
  final metresPerDegLon = metresPerDegLat * math.cos(centreLat * math.pi / 180);
  // An ellipse 1.6 : 1 with a wobble, scaled so its perimeter is about [km].
  final b = km * 1000 / (2 * math.pi * 1.32);
  final a = b * 1.6;
  return [
    for (var i = 0; i < count; i++)
      () {
        final t = i / count * 2 * math.pi;
        final wobble = 1 + 0.06 * math.sin(t * 5) + 0.03 * math.cos(t * 9);
        final x = a * math.cos(t) * wobble;
        final y = b * math.sin(t) * wobble;
        return RoutePoint(
          latitude: centreLat + y / metresPerDegLat,
          longitude: centreLon + x / metresPerDegLon,
          altitude: 24 + 9 * math.sin(t * 2) + 3 * math.sin(t * 7),
          time: start.add(every * i),
          elapsed: every * i,
        );
      }(),
  ];
}
