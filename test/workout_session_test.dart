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

  group('auto-pause', () {
    late WorkoutSession walk;

    /// Moves the clock on in quarter seconds, letting the session tick.
    Future<void> wait(WidgetTester tester, Duration d) async {
      final end = now.add(d);
      while (now.isBefore(end)) {
        now = now.add(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    testWidgets('stopping pauses it, from when the steps stopped', (
      tester,
    ) async {
      walk = WorkoutSession(
        type: WorkoutType.outdoorWalk,
        goal: WorkoutGoal.open,
        profile: const BodyProfile(),
        stepCounter: counter,
        autoPause: const Duration(seconds: 30),
        clock: () => now,
      );
      walk.begin();
      // Five minutes of walking.
      for (var i = 0; i < 300; i += 5) {
        counter.value = counter.value! + 8;
        await wait(tester, const Duration(seconds: 5));
      }
      expect(walk.autoPaused, isFalse);
      // Standing still past the wait.
      await wait(tester, const Duration(seconds: 40));
      expect(walk.autoPaused, isTrue);
      expect(walk.phase, SessionPhase.paused);
      // The half minute stood still before it paused is not counted.
      expect(walk.elapsed.inSeconds, closeTo(300, 6));

      // A step or two is not walking again; a few more are.
      counter.value = counter.value! + 3;
      await wait(tester, const Duration(seconds: 2));
      expect(walk.autoPaused, isTrue);
      counter.value = counter.value! + 5;
      await wait(tester, const Duration(seconds: 1));
      expect(walk.phase, SessionPhase.running);
      expect(walk.autoPaused, isFalse);
      walk.end();
      walk.dispose();
    });

    testWidgets('a pause by hand stays until resumed by hand', (tester) async {
      walk = WorkoutSession(
        type: WorkoutType.outdoorWalk,
        goal: WorkoutGoal.open,
        profile: const BodyProfile(),
        stepCounter: counter,
        autoPause: const Duration(seconds: 10),
        clock: () => now,
      );
      walk.begin();
      walk.pause();
      counter.value = counter.value! + 50;
      await wait(tester, const Duration(seconds: 2));
      expect(walk.phase, SessionPhase.paused);
      expect(walk.autoPaused, isFalse);
      walk.end();
      walk.dispose();
    });

    test('workouts that do not move never pause themselves', () {
      final lift = WorkoutSession(
        type: WorkoutType.strength,
        goal: WorkoutGoal.open,
        profile: const BodyProfile(),
        stepCounter: counter,
        autoPause: const Duration(seconds: 10),
        clock: () => now,
      );
      expect(lift.autoPause, isNull);
      lift.dispose();
    });
  });
}
