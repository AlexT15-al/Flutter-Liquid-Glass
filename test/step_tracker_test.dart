import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
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

  test('close readings gather into one span, written after a minute', () async {
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

  group('the counter as Android delivers it', () {
    /// The phone's step counter: it counts whatever the app is doing, and
    /// like Android tells a listener the count when it starts listening, and
    /// after that only when it changes, and only while the app is in front.
    late int hardware;
    late bool inFront;
    late List<StreamController<int>> listeners;
    var now = t0;

    setUp(() {
      hardware = 1000;
      inFront = true;
      listeners = [];
      now = t0;
      tracker = StepTracker(
        preferences: preferences,
        requiresPermission: false,
        onSpan: (span) async => written.add(span),
        clock: () => now,
        counterStream: () {
          late StreamController<int> c;
          c = StreamController<int>(
            onListen: () => scheduleMicrotask(() => c.add(hardware)),
            onCancel: () => listeners.remove(c),
          );
          listeners.add(c);
          return c.stream;
        },
      );
    });

    /// [n] steps over [seconds], told to the app only if it is in front.
    Future<void> walk(int n, int seconds) async {
      hardware += n;
      now = now.add(Duration(seconds: seconds));
      if (inFront) {
        for (final c in listeners) {
          c.add(hardware);
        }
      }
      await pumpEventQueue();
    }

    int counted() =>
        written.fold<int>(0, (t, s) => t + s.steps) +
        (tracker.pending.value?.steps ?? 0);

    test('a walk taken with the app in the background counts as soon as '
        'it is opened again', () async {
      await tracker.start();
      await pumpEventQueue();
      await walk(50, 30);
      expect(counted(), 50);

      // Into the pocket: a twenty-minute walk Android does not tell the app
      // about.
      inFront = false;
      tracker.didChangeAppLifecycleState(AppLifecycleState.paused);
      await walk(2200, 20 * 60);
      expect(counted(), 50);

      // Opened again, standing still: no new step to bring a reading.
      inFront = true;
      now = now.add(const Duration(seconds: 5));
      tracker.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      await pumpEventQueue();
      expect(counted(), 2250);
    });
  });
}
