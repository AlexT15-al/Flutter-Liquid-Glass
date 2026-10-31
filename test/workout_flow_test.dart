import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/workouts/workout_session.dart';

import 'support/harness.dart';

void main() {
  testWidgets('a workout runs from setup to summary', (tester) async {
    final harness = await Harness.create(tester);
    await tester.pumpWidget(harness.app);
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Workout').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Start a Workout'), findsOneWidget);

    // Setup sheet, open goal, Start.
    await tester.tap(find.text('Outdoor Walk'));
    await _settle(tester);
    expect(find.text('No target. End whenever you like.'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await _settle(tester);

    final controller = harness.workoutController;
    expect(controller.session, isNotNull);
    expect(controller.session!.phase, SessionPhase.countdown);

    // The countdown hands over to the clock.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.session!.phase, SessionPhase.running);
    expect(find.text('End'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    // Minimised to the pill above the tab bar, and back.
    controller.minimize();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.expanded, isFalse);
    expect(find.text('Outdoor Walk'), findsWidgets);
    controller.expand();
    await tester.pump(const Duration(seconds: 1));

    // End shows the summary.
    await tester.tap(find.text('End'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.session!.phase, SessionPhase.ended);
    expect(find.text('Workout Complete'), findsOneWidget);

    // Discard clears it.
    await tester.tap(find.text('Discard'));
    await tester.pump(const Duration(seconds: 1));
    expect(controller.session, isNull);

    await harness.tearDown(tester);
  });
}

/// Frame by frame rather than one long pump: a pushed route is built offstage
/// on its first frame and only comes onstage on a later one.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
