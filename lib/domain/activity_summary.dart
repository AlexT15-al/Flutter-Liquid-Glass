/// Steps counted between two moments.
class StepSpan {
  const StepSpan({required this.start, required this.end, required this.steps});

  final DateTime start;
  final DateTime end;
  final int steps;

  Duration get duration => end.difference(start);
}

/// One day of movement, everything the rings and the activity tiles show.
class ActivitySummary {
  const ActivitySummary({
    required this.day,
    required this.steps,
    required this.distanceKm,
    required this.activeKcal,
    required this.exerciseMinutes,
    required this.activeHours,
    required this.hourlySteps,
  });

  /// Local midnight at the start of the day.
  final DateTime day;

  final int steps;
  final double distanceKm;
  final double activeKcal;
  final double exerciseMinutes;
  final int activeHours;

  /// Steps in each of the day's 24 hours, for the hourly charts.
  final List<int> hourlySteps;

  factory ActivitySummary.empty(DateTime day) => ActivitySummary(
        day: day,
        steps: 0,
        distanceKm: 0,
        activeKcal: 0,
        exerciseMinutes: 0,
        activeHours: 0,
        hourlySteps: List.filled(24, 0),
      );
}
