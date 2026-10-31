import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/workouts/workout_session.dart';
import 'package:halo/domain/body_profile.dart';
import 'package:halo/domain/route.dart';
import 'package:halo/domain/workout.dart';

/// A metre north, in degrees of latitude, near enough anywhere.
const _metre = 1 / 111195.0;

void main() {
  late DateTime now;
  late StreamController<RoutePoint> fixes;
  late WorkoutSession session;

  RoutePoint at(double metresNorth, {double? altitude}) => RoutePoint(
    latitude: 51.5 + metresNorth * _metre,
    longitude: -0.12,
    altitude: altitude,
    time: now,
  );

  /// Delivers a fix, the way the platform stream does: asynchronously.
  Future<void> fix(double metresNorth, {double? altitude}) async {
    fixes.add(at(metresNorth, altitude: altitude));
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    now = DateTime(2026, 10, 31, 9);
    fixes = StreamController<RoutePoint>();
    session = WorkoutSession(
      type: WorkoutType.outdoorRun,
      goal: WorkoutGoal.open,
      profile: const BodyProfile(heightCm: 180, weightKg: 80),
      stepCounter: ValueNotifier<int?>(null),
      locations: fixes.stream,
      clock: () => now,
    );
  });

  tearDown(() {
    session.dispose();
    fixes.close();
  });

  test('fixes before the start move the dot but not the distance', () async {
    await fix(0);
    expect(session.position, isNotNull);
    expect(session.route, isEmpty);
    session.begin();
    await fix(0);
    now = now.add(const Duration(seconds: 30));
    await fix(100);
    expect(session.distanceKm, closeTo(0.1, 0.001));
  });

  test('standing still adds nothing', () async {
    session.begin();
    await fix(0);
    for (var i = 0; i < 20; i++) {
      now = now.add(const Duration(seconds: 1));
      await fix(i.isEven ? 1 : -1);
    }
    expect(session.route.length, 1);
    expect(session.distanceKm, 0);
  });

  test('a pause is never bridged', () async {
    session.begin();
    await fix(0);
    now = now.add(const Duration(minutes: 1));
    await fix(200);
    session.pause();
    // Walked off somewhere while paused: not counted.
    await fix(900);
    session.resume();
    await fix(1000);
    now = now.add(const Duration(minutes: 1));
    await fix(1200);
    expect(session.distanceKm, closeTo(0.4, 0.002));
    expect(session.toRecord().route.map((p) => p.segment).toSet(), {0, 1});
  });

  test('splits, pace and climb from the route', () async {
    session.begin();
    // 2.5 km at five minutes a kilometre, climbing 1 m every 50 m.
    for (var m = 0; m <= 2500; m += 50) {
      await fix(m.toDouble(), altitude: 10 + m / 50);
      now = now.add(const Duration(seconds: 15));
    }
    final splits = session.splits;
    expect(splits.length, 3);
    expect(splits[0].duration.inSeconds, closeTo(300, 1));
    expect(splits[1].duration.inSeconds, closeTo(300, 1));
    expect(splits[2].partial, closeTo(0.5, 0.01));
    expect(splits[2].pace.inSeconds, closeTo(300, 2));
    expect(session.currentPace!.inSeconds, closeTo(300, 2));
    // The last rise under the 3 m threshold is not counted, by design.
    expect(session.elevationGainM, closeTo(50, 3));
  });

  test('ending stops listening', () async {
    session.begin();
    await fix(0);
    session.end();
    expect(session.followsGps, isFalse);
    expect(fixes.hasListener, isFalse);
  });
}
