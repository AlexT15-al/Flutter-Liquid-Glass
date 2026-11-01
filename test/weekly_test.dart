import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/activity_goals.dart';
import 'package:halo/domain/activity_summary.dart';
import 'package:halo/domain/sleep.dart';
import 'package:halo/domain/weekly.dart';
import 'package:halo/domain/workout.dart';

ActivitySummary _day(DateTime day, {int steps = 0, double kcal = 0}) =>
    ActivitySummary(
      day: day,
      steps: steps,
      distanceKm: 0,
      activeKcal: kcal,
      exerciseMinutes: 0,
      activeHours: 0,
      hourlySteps: List.filled(24, 0),
      hourlyKcal: List.filled(24, 0),
      hourlyExerciseMinutes: List.filled(24, 0),
      activeHourFlags: List.filled(24, false),
    );

WorkoutRecord _workout(DateTime start) => WorkoutRecord(
  type: WorkoutType.outdoorRun,
  start: start,
  end: start.add(const Duration(minutes: 30)),
  activeDuration: const Duration(minutes: 30),
  distanceKm: 5,
  activeKcal: 300,
  steps: 0,
);

void main() {
  // A Sunday afternoon.
  final now = DateTime(2026, 11, 1, 15);
  final today = DateTime(2026, 11, 1);
  DateTime ago(int days) => DateTime(today.year, today.month, today.day - days);

  WeeklyReview review({
    required int Function(int ago) steps,
    double Function(int ago)? kcal,
    List<WorkoutRecord> workouts = const [],
    List<SleepNight> nights = const [],
  }) => WeeklyReview.of(
    days: [
      for (var i = 29; i >= 0; i--)
        _day(ago(i), steps: steps(i), kcal: kcal?.call(i) ?? 0),
    ],
    workouts: workouts,
    nights: nights,
    water: const [],
    mindful: const [],
    goals: const ActivityGoals(),
    sleepGoal: const Duration(hours: 8),
    waterGoalMl: 2500,
    now: now,
  );

  test('the week is the seven full days before today', () {
    final r = review(steps: (i) => i == 0 ? 50000 : 1000);
    expect(r.from, ago(7));
    expect(r.to, ago(1));
    // Today's 50,000 do not count.
    expect(r.thisWeek.steps, 7000);
    expect(r.lastWeek.steps, 7000);
  });

  test('more steps than the week before is the top highlight', () {
    final r = review(steps: (i) => i >= 1 && i <= 7 ? 9000 : 6000);
    final top = r.highlights.first;
    expect(top.kind, HighlightKind.steps);
    expect(top.title, 'You walked 50% more');
    expect(top.trend, Trend.up);
  });

  test('less sleep than the week before is said in minutes', () {
    final nights = [
      for (var i = 1; i <= 14; i++)
        SleepNight(
          source: SleepSource.phone,
          inBed: DateTime(today.year, today.month, today.day - i, 0),
          // 6 hours this week, 7 the week before.
          outOfBed: DateTime(
            today.year,
            today.month,
            today.day - i,
            i <= 7 ? 6 : 7,
          ),
        ),
    ];
    final r = review(steps: (_) => 0, nights: nights);
    final sleep = r.highlights.firstWhere((h) => h.kind == HighlightKind.sleep);
    expect(sleep.title, 'You slept 1 hr less a night');
    expect(sleep.trend, Trend.down);
  });

  test('a streak counts today only once it is met', () {
    // The Move goal (400) met for the last five full days; today not yet.
    final r = review(
      steps: (_) => 0,
      kcal: (i) => i >= 1 && i <= 5 ? 500 : 100,
    );
    final move = r.streaks.firstWhere((s) => s.kind == HighlightKind.move);
    expect(move.count, 5);

    final met = review(steps: (_) => 0, kcal: (i) => i <= 5 ? 500 : 100);
    expect(
      met.streaks.firstWhere((s) => s.kind == HighlightKind.move).count,
      6,
    );
  });

  test('workout weeks run Monday to Sunday', () {
    // Today is Sunday 1 November: this week began Monday 26 October.
    final r = review(
      steps: (_) => 0,
      workouts: [
        _workout(DateTime(2026, 10, 27, 7)), // this week
        _workout(DateTime(2026, 10, 20, 7)), // last week
        _workout(DateTime(2026, 10, 13, 7)), // the week before
        _workout(DateTime(2026, 9, 29, 7)), // after a gap
      ],
    );
    final weeks = r.streaks.firstWhere((s) => s.kind == HighlightKind.workouts);
    expect(weeks.count, 3);
    expect(weeks.best, 3);
  });

  test('an empty week says so', () {
    expect(review(steps: (_) => 0).empty, isTrue);
  });
}
