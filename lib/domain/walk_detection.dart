import 'activity_summary.dart';
import 'workout.dart';

/// A stretch of walking found in the steps, long and brisk enough to be a
/// walk rather than getting about.
class DetectedWalk {
  const DetectedWalk({
    required this.start,
    required this.end,
    required this.steps,
  });

  final DateTime start;
  final DateTime end;
  final int steps;

  Duration get length => end.difference(start);

  /// Steps a minute, on average.
  double get cadence => steps / (length.inSeconds / 60);

  /// What it is remembered by once dismissed.
  int get key => start.millisecondsSinceEpoch ~/ 60000;
}

/// Finds walks in the steps counted: no watch, so no heart rate, but steps
/// at walking pace for long enough are a walk.
///
/// A minute at 80 steps or more is walking (an easy walk is 90 to 100, a
/// brisk one 110 to 130; shopping or moving about the house stays well under
/// 80 over a minute). Minutes of walking with stops of up to a minute and a
/// half between them (a crossing, a traffic light) are one walk, kept only
/// if it lasted [minimum]. A walk that overlaps a workout already recorded
/// was that workout, and one the user dismissed stays dismissed.
abstract final class WalkDetector {
  static const cadence = 80.0;
  static const maxStop = Duration(seconds: 90);

  /// So the walk is over: no steps at that pace for this long.
  static const settle = Duration(minutes: 2);

  static List<DetectedWalk> detect(
    List<StepSpan> spans, {
    required Duration minimum,
    required DateTime now,
    List<WorkoutRecord> workouts = const [],
    Set<int> dismissed = const {},
  }) {
    final sorted = [...spans]..sort((a, b) => a.start.compareTo(b.start));
    final walks = <DetectedWalk>[];
    DateTime? start;
    DateTime? end;
    var steps = 0;

    void close() {
      final s = start, e = end;
      if (s != null && e != null && e.difference(s) >= minimum) {
        walks.add(DetectedWalk(start: s, end: e, steps: steps));
      }
      start = null;
      end = null;
      steps = 0;
    }

    for (final span in sorted) {
      final minutes = span.duration.inSeconds / 60;
      // Too short to judge a pace from.
      if (minutes < 0.5) continue;
      final brisk = span.steps / minutes >= cadence;
      if (!brisk) {
        close();
        continue;
      }
      final e = end;
      if (e != null && span.start.difference(e) > maxStop) close();
      start ??= span.start;
      end = span.end;
      steps += span.steps;
    }
    // Still walking: not a walk to offer yet.
    final e = end;
    if (e != null && now.difference(e) >= settle) close();

    return [
      for (final w in walks)
        if (!dismissed.contains(w.key) &&
            !workouts.any(
              (r) => r.start.isBefore(w.end) && r.end.isAfter(w.start),
            ))
          w,
    ];
  }
}
