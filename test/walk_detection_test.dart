import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/activity_summary.dart';
import 'package:halo/domain/walk_detection.dart';
import 'package:halo/domain/workout.dart';

void main() {
  final t0 = DateTime(2026, 11, 3, 18);
  final later = DateTime(2026, 11, 3, 21);

  /// [minutes] one-minute spans from [from] at [cadence] steps a minute.
  List<StepSpan> walk(DateTime from, int minutes, int cadence) => [
    for (var i = 0; i < minutes; i++)
      StepSpan(
        start: from.add(Duration(minutes: i)),
        end: from.add(Duration(minutes: i + 1)),
        steps: cadence,
      ),
  ];

  List<DetectedWalk> detect(List<StepSpan> spans, {int minimum = 10}) =>
      WalkDetector.detect(
        spans,
        minimum: Duration(minutes: minimum),
        now: later,
      );

  test('twenty minutes at walking pace is a walk', () {
    final found = detect(walk(t0, 20, 105));
    expect(found, hasLength(1));
    expect(found.single.length, const Duration(minutes: 20));
    expect(found.single.steps, 2100);
  });

  test('shorter than the minimum is not', () {
    expect(detect(walk(t0, 8, 110)), isEmpty);
    expect(detect(walk(t0, 8, 110), minimum: 5), hasLength(1));
  });

  test('pottering about is not walking', () {
    expect(detect(walk(t0, 30, 45)), isEmpty);
  });

  test('a short stop does not split a walk; a long one does', () {
    final light = [
      ...walk(t0, 8, 100),
      ...walk(t0.add(const Duration(minutes: 9)), 8, 100),
    ];
    expect(detect(light), hasLength(1));
    final cafe = [
      ...walk(t0, 8, 100),
      ...walk(t0.add(const Duration(minutes: 20)), 8, 100),
    ];
    expect(detect(cafe), isEmpty);
  });

  test('a walk still going is not offered yet', () {
    final now = t0.add(const Duration(minutes: 20, seconds: 30));
    expect(
      WalkDetector.detect(
        walk(t0, 20, 110),
        minimum: const Duration(minutes: 10),
        now: now,
      ),
      isEmpty,
    );
  });

  test('a recorded workout or a dismissed walk is not offered again', () {
    final spans = walk(t0, 20, 110);
    final recorded = WorkoutRecord(
      type: WorkoutType.outdoorWalk,
      start: t0.add(const Duration(minutes: 2)),
      end: t0.add(const Duration(minutes: 18)),
      activeDuration: const Duration(minutes: 16),
      distanceKm: 1.5,
      activeKcal: 60,
      steps: 1700,
    );
    expect(
      WalkDetector.detect(
        spans,
        minimum: const Duration(minutes: 10),
        now: later,
        workouts: [recorded],
      ),
      isEmpty,
    );
    final key = detect(spans).single.key;
    expect(
      WalkDetector.detect(
        spans,
        minimum: const Duration(minutes: 10),
        now: later,
        dismissed: {key},
      ),
      isEmpty,
    );
  });

  test('steps counted with the app closed still count as one span', () {
    // Twenty-five minutes away from the app, walking the whole time.
    final gap = StepSpan(
      start: t0,
      end: t0.add(const Duration(minutes: 25)),
      steps: 2600,
    );
    expect(detect([gap]), hasLength(1));
  });
}
