import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/workouts/workout_session.dart';
import 'package:halo/domain/body_profile.dart';
import 'package:halo/domain/workout.dart';

void main() {
  late DateTime now;
  late ValueNotifier<int?> counter;
  late WorkoutSession session;

  setUp(() {
    now = DateTime(2026, 10, 31, 9);
    counter = ValueNotifier(10000);
    session = WorkoutSession(
      type: WorkoutType.outdoorWalk,
      goal: const WorkoutGoal(WorkoutGoalKind.time, 30),
      profile: const BodyProfile(heightCm: 180, weightKg: 80),
      stepCounter: counter,
      clock: () => now,
    );
  });

  tearDown(() => session.dispose());

  test('time counts only while running', () {
    session.begin();
    now = now.add(const Duration(minutes: 10));
    session.pause();
    now = now.add(const Duration(minutes: 5));
    expect(session.elapsed, const Duration(minutes: 10));
    session.resume();
    now = now.add(const Duration(minutes: 2));
    expect(session.elapsed, const Duration(minutes: 12));
    session.end();
    now = now.add(const Duration(minutes: 30));
    expect(session.elapsed, const Duration(minutes: 12));
  });

  test('steps taken while paused are not the workout\'s', () {
    session.begin();
    counter.value = 10500;
    session.pause();
    counter.value = 10800;
    session.resume();
    counter.value = 10900;
    expect(session.steps, 600);
  });

  test('energy follows MET, weight and time', () {
    session.begin();
    now = now.add(const Duration(hours: 1));
    expect(session.activeKcal, closeTo((3.5 - 1) * 80, 1e-9));
    expect(session.goalProgress, closeTo(2, 1e-9));
  });
}
