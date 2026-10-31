import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/readiness.dart';
import 'package:halo/domain/sleep.dart';
import 'package:halo/domain/workout.dart';

void main() {
  final now = DateTime(2026, 11, 2, 9);
  const schedule = SleepSchedule(bedtimeMinutes: 23 * 60, wakeMinutes: 7 * 60);

  SleepNight night(int daysAgo, {int hours = 8}) {
    final end = DateTime(2026, 11, 2, 7).subtract(Duration(days: daysAgo));
    return SleepNight(
      source: SleepSource.manual,
      inBed: end.subtract(Duration(hours: hours)),
      outOfBed: end,
    );
  }

  WorkoutRecord workout(int daysAgo, double kcal) {
    final start = DateTime(2026, 11, 2, 18).subtract(Duration(days: daysAgo));
    return WorkoutRecord(
      type: WorkoutType.strength,
      start: start,
      end: start.add(const Duration(hours: 1)),
      activeDuration: const Duration(hours: 1),
      distanceKm: 0,
      activeKcal: kcal,
      steps: 0,
    );
  }

  test('nothing to say without last night', () {
    expect(
      Readiness.of(
        nights: [night(3)],
        workouts: const [],
        schedule: schedule,
        now: now,
      ),
      isNull,
    );
  });

  test('a full week of good sleep and steady training is ready to push', () {
    final r = Readiness.of(
      nights: [for (var d = 0; d < 7; d++) night(d)],
      workouts: [for (var d = 1; d < 28; d += 2) workout(d, 300)],
      schedule: schedule,
      now: now,
    )!;
    expect(r.value, greaterThanOrEqualTo(80));
    expect(r.loadLabel, 'Balanced');
  });

  test('a short night and a sudden jump in load bring it down', () {
    final r = Readiness.of(
      nights: [
        night(0, hours: 4),
        for (var d = 1; d < 7; d++) night(d, hours: 6),
      ],
      workouts: [
        for (var d = 14; d < 28; d += 4) workout(d, 200),
        for (var d = 0; d < 7; d++) workout(d, 600),
      ],
      schedule: schedule,
      now: now,
    )!;
    expect(r.value, lessThan(60));
    expect(r.loadRatio, greaterThan(1.5));
  });
}
