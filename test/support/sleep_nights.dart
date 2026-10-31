import 'dart:math' as math;

/// A night on the mattress, minute by minute: a while settling in, then
/// sleep with a turn now and then, and a few minutes awake at the end.
List<int> sleepCounts({
  int seed = 7,
  int settle = 20,
  int asleep = 420,
  int getUp = 12,
  int turnEvery = 41,
}) {
  final random = math.Random(seed);
  return [
    for (var i = 0; i < settle; i++) 8 + random.nextInt(10),
    for (var i = 0; i < asleep; i++)
      i % turnEvery == turnEvery - 1 || i % turnEvery == 0
          ? 9
          : random.nextDouble() < 0.06
          ? 1
          : 0,
    for (var i = 0; i < getUp; i++) 10 + random.nextInt(8),
  ];
}
