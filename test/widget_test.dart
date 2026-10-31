import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/app/halo_app.dart';
import 'package:halo/app/halo_scope.dart';
import 'package:halo/app/shell/halo_tab.dart';
import 'package:halo/data/activity/activity_store.dart';
import 'package:halo/data/activity/step_tracker.dart';
import 'package:halo/data/database/app_database.dart';
import 'package:halo/data/preferences/halo_preferences.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('shell shows Today and switches tabs', (tester) async {
    final db = AppDatabase.forExecutor(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final preferences = HaloPreferences(db);
    final activity = ActivityStore(database: db, preferences: preferences);
    final steps = StepTracker(
      preferences: preferences,
      requiresPermission: false,
      counterStream: () => const Stream.empty(),
      onSpan: activity.addSpan,
    );
    activity.attach(steps);
    await tester.runAsync(activity.load);

    await tester.pumpWidget(
      HaloScope(
        database: db,
        preferences: preferences,
        activity: activity,
        steps: steps,
        child: LiquidGlassWidgets.wrap(
          theme: const GlassThemeData.ios27(),
          child: const HaloApp(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    for (final tab in HaloTab.values) {
      expect(find.text(tab.title), findsWidgets);
    }
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);

    await tester.tap(find.text('Sleep').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Last night, your schedule and smart alarm.'),
        findsOneWidget);

    // Unmount first so the page's database streams are cancelled. Closing the
    // database itself is left to the test isolate: queries started inside the
    // fake-async zone never complete there, and a close would wait on them.
    await tester.pumpWidget(const SizedBox());
    activity.dispose();
  });
}
