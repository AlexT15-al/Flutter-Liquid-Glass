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
import 'data/preferences/halo_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only: every screen is laid out for a phone held upright, and a
  // live workout must not rotate when the phone moves in a pocket or armband.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Draw behind the system bars; `TransparentSystemBars` keeps them clear.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Async disk-to-RAM shader preload. No GPU work, so the first frame is not
  // held back, and the first glass surface does not stall compiling.
  await LiquidGlassWidgets.initialize();

  final database = AppDatabase();
  final preferences = HaloPreferences(database);
  final activity = ActivityStore(database: database, preferences: preferences);
  final steps = StepTracker(preferences: preferences, onSpan: activity.addSpan);
  activity.attach(steps);

  // Awaited, so the first frame already has today's steps rather than empty
  // rings that then jump, and opens in the stored appearance.
  await activity.load();
  final themeMode = await preferences.readThemeMode();

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
      child: LiquidGlassWidgets.wrap(
        // The iOS 27 material, premium in both appearances. Brightness is
        // resolved at each glass widget's own context, so the variants follow
        // the app's theme rather than the device's.
        theme: HaloGlass.theme,
        // No adaptive quality: it benchmarks the device on launch and can drop
        // a tier mid-session, which on chrome that is always visible reads as
        // the app degrading. Premium is the requirement.
        adaptiveQuality: false,
        child: HaloApp(initialThemeMode: themeMode),
      ),
    ),
  );
}
