import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/halo_app.dart';
import 'app/halo_scope.dart';
import 'app/theme/halo_glass.dart';
import 'data/activity/activity_store.dart';
import 'data/activity/step_tracker.dart';
import 'data/database/app_database.dart';
import 'data/location/location_tracker.dart';
import 'data/nutrition/nutrition_repository.dart';
import 'data/preferences/halo_preferences.dart';
import 'data/sleep/sleep_repository.dart';
import 'data/training/training_repository.dart';
import 'data/workouts/workout_repository.dart';
import 'features/sleep/sleep_controller.dart';
import 'features/workout/live/workout_controller.dart';
import 'features/workout/live/workout_live_activity.dart';
import 'platform/haptics.dart';

Future<void> main() async {
  // Flutter's binding, with the gate that turns haptics off when asked.
  HaloBinding.ensureInitialized();

  // Portrait only: every screen is laid out for a phone held upright, and a
  // live workout must not rotate when the phone moves in a pocket or armband.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Draw behind the system bars; `TransparentSystemBars` keeps them clear.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Async disk-to-RAM shader preload. No GPU work, so the first frame is not
  // held back, and the first glass surface does not stall compiling.
  await LiquidGlassWidgets.initialize();

  final database = AppDatabase();
  final preferences = HaloPreferences(database);
  final workouts = WorkoutRepository(database);
  final activity = ActivityStore(
    database: database,
    preferences: preferences,
    workouts: workouts,
  );
  final steps = StepTracker(preferences: preferences, onSpan: activity.addSpan);
  activity.attach(steps);
  final sleepController = SleepController(
    repository: SleepRepository(database),
    preferences: preferences,
  );
  final workoutController = WorkoutController(
    repository: workouts,
    stepCounter: steps.latestCount,
    location: const LocationTracker(),
  );

  // Awaited, so the first frame already has today's steps rather than empty
  // rings that then jump, and opens in the stored appearance.
  await activity.load();
  final themeMode = await preferences.readThemeMode();
  Haptics.enabled = await preferences.readHaptics();
  preferences.watchHaptics().listen((on) => Haptics.enabled = on);

  // The workout on the lock screen, the status bar and the Now Bar.
  WorkoutLiveActivity(
    controller: workoutController,
    enabled: preferences.watchLiveActivity(),
  ).attach();

  // A night left open (the app was closed while it tracked) is picked up or
  // closed. Not awaited: it is not on the first frame's path.
  unawaited(sleepController.restore().then((_) => sleepController.detect()));
  // Every time the app comes back, as Samsung Health does: last night is
  // there the first time the phone is opened in the morning.
  AppLifecycleListener(onResume: () => unawaited(sleepController.detect()));

  // Not awaited: checking access and opening the sensor must not hold the
  // first frame. It never prompts; asking is a button on Today.
  unawaited(steps.start());

  runApp(
    // Above the app, so every route reaches the same instances.
    HaloScope(
      database: database,
      preferences: preferences,
      activity: activity,
      steps: steps,
      workouts: workouts,
      nutrition: NutritionRepository(database),
      training: TrainingRepository(database),
      child: LiquidGlassWidgets.wrap(
        // The iOS 27 material, premium in both appearances. Brightness is
        // resolved at each glass widget's own context, so the variants follow
        // the app's theme rather than the device's.
        theme: HaloGlass.theme,
        // No adaptive quality: it benchmarks the device on launch and can drop
        // a tier mid-session, which on chrome that is always visible reads as
        // the app degrading. Premium is the requirement.
        adaptiveQuality: false,
        // Above the app, beside the tab bar's state: the workout in progress
        // outlives every route.
        child: WorkoutScope(
          controller: workoutController,
          child: SleepScope(
            controller: sleepController,
            child: HaloApp(initialThemeMode: themeMode),
          ),
        ),
      ),
    ),
  );
}
