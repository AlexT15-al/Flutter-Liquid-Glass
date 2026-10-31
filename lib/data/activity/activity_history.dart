import 'dart:isolate';

import '../../domain/activity_summary.dart';
import '../../domain/body_profile.dart';
import '../../domain/workout.dart';
import '../database/app_database.dart';
import '../workouts/workout_repository.dart';
import 'activity_math.dart';

/// Any run of past days, worked out from storage the same way Today is.
///
/// A year of five-minute step intervals is a hundred thousand rows; summing
/// every one for every day would be millions of steps of work. So the rows
/// are sorted into the days they touch first, each day is summarised from
/// its own handful, and the whole thing runs on a background isolate.
class ActivityHistory {
  ActivityHistory(this._db, this._workouts);

  final AppDatabase _db;
  final WorkoutRepository _workouts;

  /// One summary per day from [from] to [to] inclusive, oldest first.
  Future<List<ActivitySummary>> days(
    DateTime from,
    DateTime to,
    BodyProfile profile,
  ) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day + 1);
    final rows = await _db.stepIntervalsBetween(start, end);
    final spans = [
      for (final r in rows)
        StepSpan(
          start: DateTime.fromMillisecondsSinceEpoch(r.startMs),
          end: DateTime.fromMillisecondsSinceEpoch(r.endMs),
          steps: r.steps,
        ),
    ];
    final workouts = await _workouts.watchBetween(start, end).first;
    return Isolate.run(() => summarize(spans, workouts, start, end, profile));
  }

  /// The work itself, apart so a test can call it directly.
  static List<ActivitySummary> summarize(
    List<StepSpan> spans,
    List<WorkoutRecord> workouts,
    DateTime start,
    DateTime end,
    BodyProfile profile,
  ) {
    final bySpan = <DateTime, List<StepSpan>>{};
    for (final s in spans) {
      var day = DateTime(s.start.year, s.start.month, s.start.day);
      // A span over midnight belongs to both days.
      while (day.isBefore(s.end)) {
        (bySpan[day] ??= []).add(s);
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }
    final byWorkout = <DateTime, List<WorkoutRecord>>{};
    for (final w in workouts) {
      final day = DateTime(w.start.year, w.start.month, w.start.day);
      (byWorkout[day] ??= []).add(w);
    }
    return [
      for (
        var day = start;
        day.isBefore(end);
        day = DateTime(day.year, day.month, day.day + 1)
      )
        ActivityMath.summarize(
          spans: bySpan[day] ?? const [],
          day: day,
          profile: profile,
          workouts: byWorkout[day] ?? const [],
        ),
    ];
  }
}
