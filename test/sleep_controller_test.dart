import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/database/app_database.dart';
import 'package:halo/data/sleep/sleep_repository.dart';
import 'package:halo/data/sleep/sleep_sensor.dart';
import 'package:halo/domain/sleep.dart';
import 'package:halo/features/sleep/sleep_controller.dart';

import 'support/sleep_nights.dart';

class _FakeSensor extends SleepSensor {
  final minutesController = StreamController<(int, int)>.broadcast();
  bool running = false;

  @override
  Future<bool> start(DateTime inBed) async => running = true;

  @override
  Future<void> stop() async => running = false;

  @override
  Future<bool> isRunning() async => running;

  @override
  Stream<(int, int)> minutes() => minutesController.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late _FakeSensor sensor;
  late SleepRepository repository;
  late SleepController controller;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    now = DateTime(2026, 10, 30, 23);
    sensor = _FakeSensor();
    repository = SleepRepository(
      AppDatabase.forExecutor(DatabaseConnection(NativeDatabase.memory())),
    );
    controller = SleepController(
      repository: repository,
      sensor: sensor,
      clock: () => now,
    );
  });

  Future<void> feed(List<int> counts) async {
    for (var i = 0; i < counts.length; i++) {
      sensor.minutesController.add((i, counts[i]));
    }
    // Let the stores land.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  test(
    'a tracked night is stored minute by minute and scored at the end',
    () async {
      await controller.start();
      expect(controller.tracking, isTrue);
      expect(sensor.running, isTrue);

      final counts = sleepCounts();
      await feed(counts);
      now = now.add(Duration(minutes: counts.length));
      final night = await controller.stop();

      expect(controller.tracking, isFalse);
      expect(sensor.running, isFalse);
      expect(night!.hypnogram.length, counts.length);
      expect(night.asleep.inMinutes, greaterThan(380));

      final stored = await repository.watchNights(5).first;
      expect(stored.single.hypnogramCode, night.hypnogramCode);
    },
  );

  test(
    'a night left open when the tracking died is closed where it ends',
    () async {
      await controller.start();
      await feed(sleepCounts());
      // The app is killed in the night; the service with it.
      sensor.running = false;
      final reopened = SleepController(
        repository: repository,
        sensor: sensor,
        clock: () => now.add(const Duration(hours: 12)),
      );
      await reopened.restore();
      expect(reopened.tracking, isFalse);
      final night = (await repository.watchNights(5).first).single;
      expect(night.timeInBed.inMinutes, sleepCounts().length);
    },
  );

  test('a night still tracking is picked up again', () async {
    await controller.start();
    final reopened = SleepController(repository: repository, sensor: sensor);
    await reopened.restore();
    expect(reopened.tracking, isTrue);
    expect(reopened.since, now);
  });

  test('discarding keeps nothing', () async {
    await controller.start();
    await feed([3, 4, 5]);
    await controller.cancel();
    expect(await repository.open(), isNull);
    expect(await repository.watchNights(5).first, isEmpty);
  });

  test('a hand-entered night has times and no stages', () async {
    await repository.addManual(
      DateTime(2026, 10, 30, 23, 30),
      DateTime(2026, 10, 31, 7),
    );
    final night = (await repository.watchNights(5).first).single;
    expect(night.source, SleepSource.manual);
    expect(night.hasStages, isFalse);
    expect(night.asleep, const Duration(hours: 7, minutes: 30));
  });
}
