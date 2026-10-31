import 'dart:math' as math;

/// One GPS fix along a workout's route.
class RoutePoint {
  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.time,
    this.altitude,
    this.accuracy = 0,
    this.elapsed = Duration.zero,
    this.segment = 0,
  });

  final double latitude;
  final double longitude;
  final DateTime time;

  /// Metres above sea level, if the fix had it.
  final double? altitude;

  /// Horizontal accuracy radius in metres; lower is better.
  final double accuracy;

  /// The workout's moving time when the fix was taken: pauses excluded, so
  /// splits and pace are about moving.
  final Duration elapsed;

  /// Which stretch of moving this belongs to. Every resume starts a new one,
  /// and no distance is ever counted across a pause.
  final int segment;

  RoutePoint withProgress({required Duration elapsed, required int segment}) =>
      RoutePoint(
        latitude: latitude,
        longitude: longitude,
        time: time,
        altitude: altitude,
        accuracy: accuracy,
        elapsed: elapsed,
        segment: segment,
      );
}

/// The time one kilometre took.
class RouteSplit {
  const RouteSplit({required this.index, required this.duration, this.partial});

  /// 1 for the first kilometre.
  final int index;
  final Duration duration;

  /// For the last, unfinished kilometre: the fraction of it covered.
  final double? partial;

  /// Time per kilometre, scaled up for a partial last split.
  Duration get pace => partial == null || partial! <= 0
      ? duration
      : Duration(milliseconds: (duration.inMilliseconds / partial!).round());
}

/// Geometry over a route: distance, splits, climbing, recent pace.
abstract final class RouteMath {
  static const double _earthRadiusM = 6371008.8;

  /// Great-circle distance between two points, in metres (haversine).
  static double distanceM(RoutePoint a, RoutePoint b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLat = lat2 - lat1;
    final dLon = _rad(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Total distance in metres, never bridging two segments.
  static double totalM(List<RoutePoint> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].segment != points[i - 1].segment) continue;
      total += distanceM(points[i - 1], points[i]);
    }
    return total;
  }

  /// One split per whole kilometre, the moment each was crossed found by
  /// interpolating between the two fixes either side of it; then the
  /// unfinished last kilometre, if any.
  static List<RouteSplit> splits(List<RoutePoint> points) {
    final splits = <RouteSplit>[];
    var covered = 0.0;
    var nextMark = 1000.0;
    var lastMarkElapsed = points.isEmpty ? Duration.zero : points.first.elapsed;

    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      if (a.segment != b.segment) continue;
      final step = distanceM(a, b);
      if (step <= 0) continue;
      while (covered + step >= nextMark) {
        final into = (nextMark - covered) / step;
        final atMs =
            a.elapsed.inMilliseconds +
            (b.elapsed - a.elapsed).inMilliseconds * into;
        final at = Duration(milliseconds: atMs.round());
        splits.add(
          RouteSplit(index: splits.length + 1, duration: at - lastMarkElapsed),
        );
        lastMarkElapsed = at;
        nextMark += 1000;
      }
      covered += step;
    }

    final remainder = covered - (nextMark - 1000);
    if (points.length > 1 && remainder > 50) {
      splits.add(
        RouteSplit(
          index: splits.length + 1,
          duration: points.last.elapsed - lastMarkElapsed,
          partial: remainder / 1000,
        ),
      );
    }
    return splits;
  }

  /// Metres climbed.
  ///
  /// GPS altitude wanders by metres even standing still. Each fix is first
  /// averaged with two either side of it, which flattens the wander while
  /// leaving a real slope as it is; then a rise only counts once it clears
  /// [threshold] above the lowest point since the last counted climb.
  static double elevationGainM(
    List<RoutePoint> points, {
    double threshold = 3,
  }) {
    final altitudes = [for (final p in points) ?p.altitude];
    if (altitudes.length < 2) return 0;

    var gain = 0.0;
    double? base;
    for (var i = 0; i < altitudes.length; i++) {
      // Symmetric even at the ends, where a one-sided average would drag the
      // first and last fixes towards their neighbours and shave the climb.
      final reach = math.min(2, math.min(i, altitudes.length - 1 - i));
      final from = i - reach;
      final to = i + reach;
      var sum = 0.0;
      for (var j = from; j <= to; j++) {
        sum += altitudes[j];
      }
      final alt = sum / (to - from + 1);

      if (base == null || alt < base) {
        base = alt;
      } else if (alt - base >= threshold) {
        gain += alt - base;
        base = alt;
      }
    }
    return gain;
  }

  /// Pace over the last [window] of moving, or null with too little to go on.
  static Duration? recentPace(
    List<RoutePoint> points, {
    Duration window = const Duration(seconds: 30),
  }) {
    if (points.length < 2) return null;
    final end = points.last;
    var metres = 0.0;
    var start = end;
    for (var i = points.length - 1; i > 0; i--) {
      final a = points[i - 1];
      final b = points[i];
      if (a.segment != b.segment) break;
      metres += distanceM(a, b);
      start = a;
      if (end.elapsed - a.elapsed >= window) break;
    }
    final seconds = (end.elapsed - start.elapsed).inMilliseconds / 1000;
    if (metres < 20 || seconds <= 0) return null;
    return Duration(milliseconds: (seconds / metres * 1000 * 1000).round());
  }

  static double _rad(double degrees) => degrees * math.pi / 180;
}
