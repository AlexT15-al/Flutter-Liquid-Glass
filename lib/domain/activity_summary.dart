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
    required this.hourlyKcal,
    required this.hourlyExerciseMinutes,
    required this.activeHourFlags,
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

  /// Active energy in each hour, summing to [activeKcal].
  final List<double> hourlyKcal;

  /// Exercise minutes in each hour, summing to [exerciseMinutes].
  final List<double> hourlyExerciseMinutes;

  /// Whether each hour counted as active: enough steps, or enough workout.
  final List<bool> activeHourFlags;

  /// Steps in an hour for it to count as active. Mirrors
  /// `ActivityMath.activeHourSteps`, which sets it.
  static const int activeHourThreshold = 250;

  factory ActivitySummary.empty(DateTime day) => ActivitySummary(
    day: day,
    steps: 0,
    distanceKm: 0,
    activeKcal: 0,
    exerciseMinutes: 0,
    activeHours: 0,
    hourlySteps: List.filled(24, 0),
    hourlyKcal: List.filled(24, 0),
    hourlyExerciseMinutes: List.filled(24, 0),
    activeHourFlags: List.filled(24, false),
  );
}
