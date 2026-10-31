import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/route.dart';

void main() {
  final t0 = DateTime(2026, 10, 31, 8);

  /// A point [metres] north of the start, at [seconds] of moving time.
  RoutePoint north(
    double metres,
    int seconds, {
    int segment = 0,
    double? altitude,
  }) {
    // One degree of latitude is about 111,195 m on the mean-radius sphere.
    return RoutePoint(
      latitude: 37.9 + metres / 111195.0,
      longitude: 23.7,
      time: t0.add(Duration(seconds: seconds)),
      elapsed: Duration(seconds: seconds),
      segment: segment,
      altitude: altitude,
    );
  }

  test('distance along a straight line', () {
    final route = [north(0, 0), north(500, 150), north(1000, 300)];
    expect(RouteMath.totalM(route), closeTo(1000, 1));
  });

  test('no distance is counted across a pause', () {
    final route = [
      north(0, 0),
      north(400, 120),
      // Walked 300 m while paused: not counted.
      north(700, 120, segment: 1),
      north(1000, 210, segment: 1),
    ];
    expect(RouteMath.totalM(route), closeTo(700, 1));
  });

  test('splits are interpolated at each kilometre', () {
    final route = [north(0, 0), north(1500, 600), north(2600, 1040)];
    final splits = RouteMath.splits(route);
    expect(splits, hasLength(3));
    expect(splits[0].duration.inSeconds, closeTo(400, 1));
    expect(splits[1].duration.inSeconds, closeTo(400, 1));
    // The last 600 m took 240 s: a 400 s/km pace.
    expect(splits[2].partial, closeTo(0.6, 0.01));
    expect(splits[2].pace.inSeconds, closeTo(400, 2));
  });

  test('altitude noise does not add up into a climb', () {
    final wobble = [
      for (var i = 0; i < 40; i++)
        north(i * 10, i * 4, altitude: 100 + (i.isEven ? 1.5 : -1.5)),
    ];
    expect(RouteMath.elevationGainM(wobble), 0);

    final hill = [
      for (var i = 0; i <= 20; i++) north(i * 10, i * 4, altitude: 100 + i * 2),
    ];
    expect(RouteMath.elevationGainM(hill), closeTo(40, 3));
  });

  test('recent pace comes from the last stretch', () {
    final route = [for (var i = 0; i <= 10; i++) north(i * 15, i * 5)];
    // 15 m every 5 s is 3 m/s: 333 s per km.
    expect(RouteMath.recentPace(route)!.inSeconds, closeTo(333, 2));
  });
}
