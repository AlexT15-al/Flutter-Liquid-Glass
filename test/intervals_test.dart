import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/intervals.dart';
import 'package:halo/domain/workout.dart';

void main() {
  const warmup = IntervalStep(StepKind.warmup, StepMeasure.time, 300);
  const cooldown = IntervalStep(StepKind.cooldown, StepMeasure.time, 120);
  const work = IntervalStep(StepKind.work, StepMeasure.distance, 400);
  const recover = IntervalStep(StepKind.recover, StepMeasure.time, 90);

  const repeats = CustomWorkout(
    id: 1,
    name: '3 × 400 m',
    type: WorkoutType.outdoorRun,
    warmup: warmup,
    blocks: [IntervalBlock(repeats: 3, work: work, recover: recover)],
    cooldown: cooldown,
  );

  test('repeats are spelled out, with no recovery before the cool-down', () {
    expect(
      [for (final s in repeats.segments) s.label],
      [
        'Warm Up',
        'Work 1 of 3',
        'Recover 1 of 3',
        'Work 2 of 3',
        'Recover 2 of 3',
        'Work 3 of 3',
        'Cool Down',
      ],
    );
  });

  test('the estimate counts distance at the given pace', () {
    // 300 + 3 × 400 m at 6:00 (144 s) + 2 × 90 + 120.
    expect(repeats.estimate().inSeconds, 300 + 3 * 144 + 180 + 120);
  });

  test('time steps end on time, distance steps on distance', () {
    final t = IntervalTracker(repeats);
    expect(t.update(const Duration(seconds: 299), 0.8), isFalse);
    expect(t.current!.label, 'Warm Up');
    expect(t.timeLeft, const Duration(seconds: 1));

    // The warm-up ends at 300 s; the first 400 m start from there.
    expect(t.update(const Duration(seconds: 300), 0.8), isTrue);
    expect(t.current!.label, 'Work 1 of 3');
    t.update(const Duration(seconds: 360), 1.0);
    expect(t.metresLeft, 200);
    expect(t.progress, closeTo(0.5, 1e-9));

    t.update(const Duration(seconds: 400), 1.2);
    expect(t.current!.label, 'Recover 1 of 3');
    // Recovery is timed from where the work ended.
    t.update(const Duration(seconds: 460), 1.3);
    expect(t.timeLeft, const Duration(seconds: 30));
  });

  test('a long gap crosses several steps at once', () {
    final t = IntervalTracker(repeats);
    // Warm-up done, the first 400 m run, and the first recovery over.
    expect(t.update(const Duration(seconds: 300), 0), isTrue);
    t.update(const Duration(seconds: 380), 0.4);
    expect(t.current!.label, 'Recover 1 of 3');
    t.update(const Duration(seconds: 2000), 0.4);
    expect(t.current!.label, 'Work 2 of 3');
  });

  test('skip ends the step now', () {
    final t = IntervalTracker(repeats)..update(const Duration(seconds: 10), 0);
    t.skip();
    expect(t.current!.label, 'Work 1 of 3');
    t.update(const Duration(seconds: 20), 0.1);
    expect(t.metresLeft, 300);
  });

  test('done after the last step', () {
    final t = IntervalTracker(
      const CustomWorkout(
        id: 2,
        name: 'One',
        type: WorkoutType.hiit,
        blocks: [
          IntervalBlock(
            repeats: 1,
            work: IntervalStep(StepKind.work, StepMeasure.time, 30),
          ),
        ],
      ),
    );
    t.update(const Duration(seconds: 31), 0);
    expect(t.done, isTrue);
    expect(t.current, isNull);
  });

  test('survives a round trip through JSON', () {
    final back = CustomWorkout.fromJson(repeats.toJson());
    expect(back.name, repeats.name);
    expect(back.type, repeats.type);
    expect(back.describe, repeats.describe);
    expect(back.segments.length, repeats.segments.length);
  });

  test('the starter suits the workout', () {
    final run = CustomWorkout.starter(WorkoutType.outdoorRun, id: 1);
    expect(run.blocks.single.work.measure, StepMeasure.distance);
    final hiit = CustomWorkout.starter(WorkoutType.hiit, id: 1);
    expect(hiit.blocks.single.work.measure, StepMeasure.time);
  });
}
