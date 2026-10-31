import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/activity/step_tracker.dart';
import 'package:halo/data/database/app_database.dart';
import 'package:halo/data/preferences/halo_preferences.dart';
import 'package:halo/domain/activity_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HaloPreferences preferences;
  late List<StepSpan> written;
  late StepTracker tracker;

  final t0 = DateTime(2026, 10, 31, 9);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  StepTracker build() => StepTracker(
        preferences: preferences,
        requiresPermission: false,
        onSpan: (span) async => written.add(span),
      );

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    preferences = HaloPreferences(db);
    written = [];
    tracker = build();
  });

  tearDown(() => db.close());

  test('the first reading only sets a baseline', () async {
    await tracker.record(5000, at(0));
    expect(written, isEmpty);
    expect(tracker.pending.value, isNull);
    expect((await preferences.readStepCounter())!.count, 5000);
  });

  test('close readings gather into one span, written after a minute',
      () async {
    await tracker.record(1000, at(0));
    await tracker.record(1010, at(10));
    await tracker.record(1030, at(30));
    expect(written, isEmpty);
    expect(tracker.pending.value!.steps, 30);

    await tracker.record(1100, at(61));
    expect(written, hasLength(1));
    expect(written.single.steps, 100);
    expect(written.single.start, at(0));
    expect(written.single.end, at(61));
    expect(tracker.pending.value, isNull);
    expect((await preferences.readStepCounter())!.count, 1100);
  });

  test('a long silence becomes a gap span of its own', () async {
    await tracker.record(1000, at(0));
    await tracker.record(1020, at(20));
    await tracker.record(1520, at(3600));

    expect(written, hasLength(2));
    expect(written[0].steps, 20);
    expect(written[1].steps, 500);
    expect(written[1].start, at(20));
    expect(written[1].end, at(3600));
  });

  test('a reboot counts the new total as new steps', () async {
    await tracker.record(9000, at(0));
    await tracker.record(120, at(4000));
    expect(written.single.steps, 120);
  });

  test('steps open at a crash come back in the next gap, once', () async {
    await tracker.record(1000, at(0));
    await tracker.record(1040, at(30));
    // The app dies here: the open span was never written.

    final restarted = build();
    await restarted.start();
    await restarted.record(1240, at(900));

    expect(written.single.steps, 240);
    expect(written.single.start, at(0));
    await restarted.dispose();
  });
}
