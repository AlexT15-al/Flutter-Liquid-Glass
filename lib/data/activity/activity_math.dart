import 'dart:math' as math;

import '../../domain/activity_summary.dart';
import '../../domain/body_profile.dart';
import '../../domain/workout.dart';

/// Turns counted steps into the day's activity numbers.
///
/// Pure and synchronous: the same spans and profile always give the same
/// summary, which is what lets the store memoise it and the tests pin it.
///
/// None of this is a measurement. A phone sees steps and time, nothing more,
/// so energy and intensity are estimated from cadence: published walking
/// research ties steps per minute to intensity closely enough for a daily
/// trend, which is what the rings show.
abstract final class ActivityMath {
  /// Steps per minute from which walking counts as moderate intensity, the
  /// widely used 100 steps/min threshold. A minute at this pace counts towards
  /// the Exercise ring.
  static const double exerciseCadence = 100;

  /// Steps per minute above which the movement is treated as running: longer
  /// strides and roughly twice the energy per kilometre.
  static const double runningCadence = 140;

  /// Steps in an hour for it to count as an active hour.
  static const int activeHourSteps = ActivitySummary.activeHourThreshold;

  /// Net energy cost of walking, kcal per kilogram per kilometre, above
  /// resting. Close to flat across ordinary walking speeds.
  static const double walkingKcalPerKgKm = 0.5;

  /// Net energy cost of running, kcal per kilogram per kilometre.
  static const double runningKcalPerKgKm = 1.0;

  /// A running stride is longer than a walking one for the same person.
  static const double runningStrideFactor = 1.3;

  /// Minutes of workout in an hour for it to count as active, whatever the
  /// step count: a ride or a yoga session barely moves the step counter.
  static const double activeHourWorkoutMinutes = 5;

  /// Summarises [day] (any moment in it) from [spans] and [workouts], which
  /// may start before or end after the day: only the part inside it counts.
  ///
  /// Workouts and steps overlap, and nothing is counted twice:
  ///
  /// - **Exercise:** a workout's moving time counts in full; brisk walking
  ///   found in the steps counts only outside workouts.
  /// - **Move:** walking and running workouts are already in the steps, so
  ///   only the energy of workouts the step counter cannot see is added.
  static ActivitySummary summarize({
    required Iterable<StepSpan> spans,
    required DateTime day,
    required BodyProfile profile,
    Iterable<WorkoutRecord> workouts = const [],
  }) {
    final dayStart = DateTime(day.year, day.month, day.day);
    // The next midnight by calendar, not by adding 24 hours: a day that
    // changes the clocks is 23 or 25 hours long.
    final dayEnd = DateTime(day.year, day.month, day.day + 1);

    final hourly = List<double>.filled(24, 0);
    final hourlyKcal = List<double>.filled(24, 0);
    final hourlyExercise = List<double>.filled(24, 0);
    var steps = 0.0;
    var distanceKm = 0.0;
    var kcal = 0.0;
    var exerciseMinutes = 0.0;
    final hourlyWorkout = List<double>.filled(24, 0);

    // Each workout's part of the day, and the share of it that was moving
    // rather than paused.
    final windows = <(DateTime, DateTime, WorkoutRecord)>[];
    for (final workout in workouts) {
      final from = _later(workout.start, dayStart);
      final to = _earlier(workout.end, dayEnd);
      if (!to.isAfter(from)) continue;
      windows.add((from, to, workout));

      final totalMs = math.max(
        workout.end.difference(workout.start).inMilliseconds,
        1,
      );
      final share = to.difference(from).inMilliseconds / totalMs;
      final minutes = workout.activeDuration.inMilliseconds / 60000 * share;

      exerciseMinutes += minutes;
      _spread(hourlyExercise, from, to, minutes);
      _spread(hourlyWorkout, from, to, minutes);
      if (!workout.type.steps) {
        final energy = workout.activeKcal * share;
        kcal += energy;
        _spread(hourlyKcal, from, to, energy);
      }
    }

    for (final span in spans) {
      if (span.steps <= 0) continue;
      final instant = !span.end.isAfter(span.start);
      if (instant) {
        // Belongs to the day only if the moment itself is inside it.
        if (span.start.isBefore(dayStart) || !span.start.isBefore(dayEnd)) {
          continue;
        }
      }
      final from = _later(span.start, dayStart);
      final to = _earlier(span.end, dayEnd);
      final overlapMs = to.difference(from).inMilliseconds;
      if (!instant && overlapMs <= 0) continue;

      // A span with no duration (two readings in the same millisecond) still
      // has steps: give them a nominal second so nothing divides by zero.
      final durationMs = math.max(span.duration.inMilliseconds, 1000);
      final share = overlapMs <= 0 ? 1.0 : overlapMs / durationMs;
      final cadence = span.steps / (durationMs / 60000);
      final running = cadence >= runningCadence;

      final spanSteps = span.steps * share;
      final stride =
          profile.walkingStrideMeters * (running ? runningStrideFactor : 1.0);
      final km = spanSteps * stride / 1000;

      final spanKcal =
          km *
          profile.weightKg *
          (running ? runningKcalPerKgKm : walkingKcalPerKgKm);
      // Brisk minutes inside a workout are already the workout's.
      final insideWorkouts = cadence >= exerciseCadence
          ? windows.fold<int>(
              0,
              (sum, w) => sum + _overlapMs(from, to, w.$1, w.$2),
            )
          : 0;
      final spanExercise = cadence >= exerciseCadence
          ? math.max(overlapMs - insideWorkouts, 0) / 60000
          : 0.0;

      steps += spanSteps;
      distanceKm += km;
      kcal += spanKcal;
      exerciseMinutes += spanExercise;

      // Everything in the span is spread over the clock hours it covers in
      // proportion to time, so the hourly charts add up to the day's totals.
      final until = overlapMs <= 0 ? from : to;
      _spread(hourly, from, until, spanSteps);
      _spread(hourlyKcal, from, until, spanKcal);
      if (spanExercise > 0) _spread(hourlyExercise, from, until, spanExercise);
    }

    final hourlySteps = [for (final h in hourly) h.round()];
    final activeFlags = [
      for (var h = 0; h < 24; h++)
        hourlySteps[h] >= activeHourSteps ||
            hourlyWorkout[h] >= activeHourWorkoutMinutes,
    ];

    return ActivitySummary(
      day: dayStart,
      steps: steps.round(),
      distanceKm: distanceKm,
      activeKcal: kcal,
      exerciseMinutes: exerciseMinutes,
      activeHours: activeFlags.where((active) => active).length,
      hourlySteps: hourlySteps,
      activeHourFlags: List.unmodifiable(activeFlags),
      hourlyKcal: List.unmodifiable(hourlyKcal),
      hourlyExerciseMinutes: List.unmodifiable(hourlyExercise),
    );
  }

  /// Adds [total] to [hourly], split over the clock hours between [from] and
  /// [to] in proportion to the time spent in each. An instant puts it all in
  /// its own hour.
  static void _spread(
    List<double> hourly,
    DateTime from,
    DateTime to,
    double total,
  ) {
    final spanMs = to.difference(from).inMilliseconds;
    if (spanMs <= 0) {
      hourly[from.hour] += total;
      return;
    }
    var cursor = from;
    while (cursor.isBefore(to)) {
      final nextHour = DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        cursor.hour + 1,
      );
      final segmentEnd = _earlier(nextHour, to);
      hourly[cursor.hour] +=
          total * segmentEnd.difference(cursor).inMilliseconds / spanMs;
      cursor = segmentEnd;
    }
  }

  static int _overlapMs(DateTime a0, DateTime a1, DateTime b0, DateTime b1) {
    final from = _later(a0, b0);
    final to = _earlier(a1, b1);
    return math.max(to.difference(from).inMilliseconds, 0);
  }

  static DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
