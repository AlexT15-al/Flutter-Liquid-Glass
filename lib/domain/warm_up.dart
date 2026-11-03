import 'dart:math' as math;

import 'training.dart';

/// One move of the general warm-up, and how much of it.
class WarmUpMove {
  const WarmUpMove(this.name, this.amount);

  final String name;
  final String amount;
}

/// A lighter set before the working sets.
class WarmUpSet {
  const WarmUpSet({required this.reps, required this.kg});

  final int reps;
  final double kg;
}

/// Getting ready for a session: a few minutes to raise the heart rate and
/// loosen what is about to work, then, for each heavy lift, lighter sets
/// that climb to the working load.
abstract final class WarmUp {
  /// The empty Olympic bar.
  static const bar = 20.0;

  /// About five to eight minutes: something easy to get warm, then moves
  /// for the joints the session uses.
  static List<WarmUpMove> general(PlannedSession session, TrainingPlace place) {
    final patterns = {for (final e in session.exercises) e.exercise.pattern};
    final lower = patterns.any(
      (p) => {
        Pattern.squat,
        Pattern.hinge,
        Pattern.lunge,
        Pattern.legs,
      }.contains(p),
    );
    final push = patterns.any(
      (p) => p == Pattern.pushHorizontal || p == Pattern.pushVertical,
    );
    final pull = patterns.any(
      (p) => p == Pattern.pullHorizontal || p == Pattern.pullVertical,
    );
    return [
      WarmUpMove(
        place == TrainingPlace.gym
            ? 'Bike, rower or brisk walk'
            : 'Marching on the spot, then jumping jacks',
        '3 min, easy',
      ),
      if (lower) ...const [
        WarmUpMove('Hip circles', '10 each way'),
        WarmUpMove('Leg swings', '10 each leg'),
        WarmUpMove('Bodyweight squats', '10, slow'),
      ],
      if (push) ...const [
        WarmUpMove('Arm circles', '10 each way'),
        WarmUpMove('Scapular push-ups', '10'),
      ],
      if (pull) ...[
        WarmUpMove(
          place == TrainingPlace.gym ? 'Band pull-aparts' : 'Wall slides',
          place == TrainingPlace.gym ? '15' : '10',
        ),
        const WarmUpMove('Cat-cow', '8, slow'),
      ],
      if (!lower && !push && !pull)
        const WarmUpMove('World’s greatest stretch', '5 each side'),
    ];
  }

  /// The ramp to a heavy lift's working load: a heavier load gets more
  /// steps. Light lifts, small muscles and body weight need none.
  static List<WarmUpSet> sets(PlannedExercise planned, {double step = 2.5}) {
    final kg = planned.kg;
    final pattern = planned.exercise.pattern;
    final compound = !{
      Pattern.arms,
      Pattern.legs,
      Pattern.core,
      Pattern.conditioning,
    }.contains(pattern);
    if (kg == null || !compound || kg < 20) return const [];

    double at(double share) {
      final raw = kg * share;
      final rounded = (raw / step).round() * step;
      // A barbell lift starts no lighter than the bar.
      return planned.exercise.dumbbell
          ? math.max(step, rounded)
          : math.max(bar, rounded);
    }

    final ramp = kg >= 60
        ? const [(0.0, 10), (0.4, 8), (0.6, 5), (0.8, 3)]
        : kg >= 35
        ? const [(0.0, 10), (0.5, 6), (0.75, 3)]
        : const [(0.5, 8), (0.75, 4)];
    final out = <WarmUpSet>[];
    for (final (share, reps) in ramp) {
      // 0 is the empty bar (half the load for dumbbells).
      final load = share == 0
          ? (planned.exercise.dumbbell ? at(0.5) : bar)
          : at(share);
      // Never as heavy as the work, nor the same load twice.
      if (load >= kg) continue;
      // Each step a real step up: 20 then 22.5 kg is the same set twice.
      if (out.isNotEmpty && load - out.last.kg < math.max(5, kg * 0.1)) {
        continue;
      }
      out.add(WarmUpSet(reps: reps, kg: load));
    }
    return out;
  }
}
