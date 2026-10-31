import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/app/halo_app.dart';
import 'package:halo/app/halo_scope.dart';
import 'package:halo/data/activity/activity_store.dart';
import 'package:halo/data/activity/step_tracker.dart';
import 'package:halo/data/database/app_database.dart';
import 'package:halo/data/location/location_tracker.dart';
import 'package:halo/data/preferences/halo_preferences.dart';
import 'package:halo/data/workouts/workout_repository.dart';
import 'package:halo/features/workout/live/workout_controller.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The whole app over an in-memory database, wired the way `main` wires it.
class Harness {
  Harness._(
    this.db,
    this.preferences,
    this.activity,
    this.steps,
    this.workouts,
    this.workoutController,
  );

  final AppDatabase db;
  final HaloPreferences preferences;
  final ActivityStore activity;
  final StepTracker steps;
  final WorkoutRepository workouts;
  final WorkoutController workoutController;

  /// Builds the services. Database work runs in [WidgetTester.runAsync]:
  /// queries started inside the fake-async zone never complete.
  static Future<Harness> create(
    WidgetTester tester, {
    Future<void> Function(Harness harness)? seed,
    LocationTracker? location,
    DateTime Function()? clock,
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase.forExecutor(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final preferences = HaloPreferences(db);
    final workouts = WorkoutRepository(db);
    final activity = ActivityStore(
      database: db,
      preferences: preferences,
      workouts: workouts,
    );
    final steps = StepTracker(
      preferences: preferences,
      requiresPermission: false,
      counterStream: () => const Stream.empty(),
      onSpan: activity.addSpan,
    );
    activity.attach(steps);
    final controller = WorkoutController(
      repository: workouts,
      stepCounter: steps.latestCount,
      location: location,
      clock: clock,
    );
    final harness = Harness._(
      db,
      preferences,
      activity,
      steps,
      workouts,
      controller,
    );
    await tester.runAsync(() async {
      await activity.load();
      await seed?.call(harness);
      await steps.start();
    });
    return harness;
  }

  Widget get app => HaloScope(
    database: db,
    preferences: preferences,
    activity: activity,
    steps: steps,
    workouts: workouts,
    child: LiquidGlassWidgets.wrap(
      theme: const GlassThemeData.ios27(),
      child: WorkoutScope(
        controller: workoutController,
        child: const HaloApp(),
      ),
    ),
  );

  /// Unmounts first, so the pages' database streams are cancelled; the
  /// database itself is left to the test isolate.
  Future<void> tearDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    activity.dispose();
  }
}
