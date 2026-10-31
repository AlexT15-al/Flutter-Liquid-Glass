import 'dart:math' as math;

import 'sleep.dart';
import 'workout.dart';

/// How ready the body is today, out of 100, and the three things it comes
/// from.
///
/// Without a watch there is no heart rate to read recovery from, so it rests
/// on what the phone does know:
///
/// - **Last night** (half): the night's sleep score.
/// - **The week's sleep** (15%): the average asleep over the last seven
///   nights against the goal; a debt builds up and takes a while to pay off.
/// - **Training load** (35%): the last seven days of workout energy against
///   the last 28 (the acute-to-chronic ratio sports science uses). Up to 1.3
///   is a load the body is used to; much past that, injury and fatigue risk
///   climb.
class Readiness {
  const Readiness._({
    required this.value,
    required this.lastNight,
    required this.sleepWeek,
    required this.load,
    required this.loadRatio,
    required this.weekAverage,
  });

  final int value;

  /// Each part from 0 to 1.
  final double lastNight;
  final double sleepWeek;
  final double load;

  /// Acute over chronic load; null without four weeks' history worth
  /// comparing to.
  final double? loadRatio;

  final Duration weekAverage;

  String get label => switch (value) {
    >= 80 => 'Ready to Push',
    >= 60 => 'Steady',
    >= 40 => 'Take It Easy',
    _ => 'Rest Day',
  };

  String get loadLabel {
    final ratio = loadRatio;
    if (ratio == null) return 'Building up';
    if (ratio < 0.8) return 'Lighter than usual';
    if (ratio <= 1.3) return 'Balanced';
    if (ratio <= 1.5) return 'High';
    return 'Very high';
  }

  /// Null until last night (the night that ended today or yesterday) is in.
  static Readiness? of({
    required List<SleepNight> nights,
    required List<WorkoutRecord> workouts,
    required SleepSchedule schedule,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final recent = [
      for (final n in nights)
        if (today.difference(n.morning).inDays <= 1) n,
    ];
    if (recent.isEmpty) return null;
    final last = recent.reduce(
      (a, b) => a.outOfBed.isAfter(b.outOfBed) ? a : b,
    );
    final lastNight = SleepScore.of(last, schedule).value / 100;

    final week = [
      for (final n in nights)
        if (today.difference(n.morning).inDays < 7) n,
    ];
    final mornings = {for (final n in week) n.morning};
    final totalAsleep = week.fold<int>(0, (t, n) => t + n.asleep.inMinutes);
    final average = Duration(
      minutes: mornings.isEmpty ? 0 : totalAsleep ~/ mornings.length,
    );
    final sleepWeek = (average.inMinutes / schedule.goal.inMinutes).clamp(
      0.0,
      1.0,
    );

    double energy(int fromDaysAgo, int toDaysAgo) => workouts
        .where((w) {
          final days = today.difference(w.start).inDays;
          return days >= toDaysAgo && days < fromDaysAgo;
        })
        .fold<double>(0, (t, w) => t + w.activeKcal);
    final acute = energy(7, 0) / 7;
    final chronic = energy(28, 0) / 28;
    final hasHistory = workouts.any(
      (w) => today.difference(w.start).inDays >= 14,
    );
    final ratio = hasHistory && chronic > 0 ? acute / chronic : null;
    final load = ratio == null || ratio <= 1.3
        ? 1.0
        : (1 - (ratio - 1.3) / 0.7 * 0.7).clamp(0.3, 1.0);

    final value = (50 * lastNight + 15 * sleepWeek + 35 * load).round();
    return Readiness._(
      value: math.min(100, value),
      lastNight: lastNight,
      sleepWeek: sleepWeek,
      load: load,
      loadRatio: ratio,
      weekAverage: average,
    );
  }
}
