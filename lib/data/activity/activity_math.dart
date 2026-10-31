import 'dart:math' as math;

import '../../domain/activity_summary.dart';
import '../../domain/body_profile.dart';

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

  /// Summarises [day] (any moment in it) from [spans], which may start before
  /// or end after the day: only the part inside the day counts.
  static ActivitySummary summarize({
    required Iterable<StepSpan> spans,
    required DateTime day,
    required BodyProfile profile,
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
      final stride = profile.walkingStrideMeters *
          (running ? runningStrideFactor : 1.0);
      final km = spanSteps * stride / 1000;

      final spanKcal = km *
          profile.weightKg *
          (running ? runningKcalPerKgKm : walkingKcalPerKgKm);
      final spanExercise =
          cadence >= exerciseCadence ? math.max(overlapMs, 0) / 60000 : 0.0;

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

    return ActivitySummary(
      day: dayStart,
      steps: steps.round(),
      distanceKm: distanceKm,
      activeKcal: kcal,
      exerciseMinutes: exerciseMinutes,
      activeHours: hourlySteps.where((s) => s >= activeHourSteps).length,
      hourlySteps: hourlySteps,
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
      final nextHour =
          DateTime(cursor.year, cursor.month, cursor.day, cursor.hour + 1);
      final segmentEnd = _earlier(nextHour, to);
      hourly[cursor.hour] +=
          total * segmentEnd.difference(cursor).inMilliseconds / spanMs;
      cursor = segmentEnd;
    }
  }

  static DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
