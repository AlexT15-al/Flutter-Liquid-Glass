import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/activity/activity_store.dart';
import 'package:halo/data/activity/step_tracker.dart';
import 'package:halo/data/database/app_database.dart';
import 'package:halo/data/preferences/halo_preferences.dart';
import 'package:halo/data/workouts/workout_repository.dart';
import 'package:halo/domain/activity_summary.dart';
import 'package:halo/domain/workout.dart';
import 'package:halo/features/workout/live/workout_controller.dart';
import 'package:halo/domain/body_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late HaloPreferences prefs;
  late WorkoutRepository workouts;
  late ActivityStore store;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forExecutor(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    prefs = HaloPreferences(db);
    workouts = WorkoutRepository(db);
    store = ActivityStore(database: db, preferences: prefs, workouts: workouts);
    await store.load();
  });

  // Steps and workouts: a workout's steps are counted in the day once,
  // whether it is detected and saved or recorded live.
  test('saving a detected walk keeps its steps in the day', () async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 0, 10);
    for (var i = 0; i < 20; i++) {
      await store.addSpan(
        StepSpan(
          start: start.add(Duration(minutes: i)),
          end: start.add(Duration(minutes: i + 1)),
          steps: 110,
        ),
      );
    }
    final before = store.today.steps;
    await workouts.save(
      WorkoutRecord(
        type: WorkoutType.outdoorWalk,
        start: start,
        end: start.add(const Duration(minutes: 20)),
        activeDuration: const Duration(minutes: 20),
        distanceKm: 1.6,
        activeKcal: 80,
        steps: 2200,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(store.today.steps, before);
  });

  test('steps counted during a live workout reach the day', () async {
    final today = DateTime.now();
    var now = DateTime(today.year, today.month, today.day, 0, 5);
    store = ActivityStore(
      database: db,
      preferences: prefs,
      workouts: workouts,
      clock: () => now,
    );
    await store.load();
    final counter = StreamController<int>();
    final tracker = StepTracker(
      preferences: prefs,
      requiresPermission: false,
      counterStream: () => counter.stream,
      onSpan: store.addSpan,
      clock: () => now,
    );
    store.attach(tracker);
    await tracker.start();
    final controller = WorkoutController(
      repository: workouts,
      stepCounter: tracker.latestCount,
      clock: () => now,
    );
    counter.add(10000);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await controller.start(
      type: WorkoutType.outdoorWalk,
      goal: WorkoutGoal.open,
      profile: const BodyProfile(),
    );
    controller.skipCountdown();
    // Twenty minutes of walking, a reading every half minute.
    for (var i = 1; i <= 40; i++) {
      now = now.add(const Duration(seconds: 30));
      counter.add(10000 + i * 55);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    // The walk's steps are the day's as they are taken.
    expect(controller.session!.steps, 2200);
    expect(store.today.steps, 2200);
    controller.session!.end();
    await controller.save();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(store.today.steps, 2200);
  });
}
