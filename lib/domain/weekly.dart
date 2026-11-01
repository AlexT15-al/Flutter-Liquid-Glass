import 'activity_goals.dart';
import 'activity_summary.dart';
import 'mindfulness.dart';
import 'sleep.dart';
import 'workout.dart';

/// What a highlight is about: sets its glyph and colour.
enum HighlightKind { steps, move, exercise, workouts, sleep, water, mindful }

/// Which way a highlight points.
enum Trend { up, down, steady }

/// One thing worth saying about the week, in a sentence.
class Highlight {
  const Highlight({
    required this.kind,
    required this.title,
    required this.detail,
    this.trend = Trend.steady,
    this.weight = 0,
  });

  final HighlightKind kind;

  /// "You walked 12% more"
  final String title;

  /// "8,240 steps a day, against 7,350 the week before."
  final String detail;

  /// Whether it is better or worse than before; for the arrow.
  final Trend trend;

  /// How much it is worth saying: highlights are shown biggest first.
  final double weight;
}

/// A run of days (or weeks) in a row that met a goal.
class Streak {
  const Streak({
    required this.kind,
    required this.title,
    required this.count,
    required this.unit,
    required this.best,
  });

  final HighlightKind kind;
  final String title;
  final int count;

  /// "days" or "weeks".
  final String unit;

  /// The longest run in the history looked at.
  final int best;
}

/// Seven days, added up.
class WeekTotals {
  const WeekTotals({
    required this.days,
    required this.steps,
    required this.moveKcal,
    required this.exerciseMinutes,
    required this.moveGoalDays,
    required this.stepGoalDays,
    required this.workouts,
    required this.workoutTime,
    required this.sleepNights,
    required this.sleep,
    required this.waterDays,
    required this.waterMl,
    required this.mindfulMinutes,
    required this.bestDay,
  });

  final int days;
  final int steps;
  final double moveKcal;
  final double exerciseMinutes;
  final int moveGoalDays;
  final int stepGoalDays;
  final int workouts;
  final Duration workoutTime;

  /// Nights recorded, and their time asleep altogether.
  final int sleepNights;
  final Duration sleep;

  /// Days with water logged, and the water altogether.
  final int waterDays;
  final int waterMl;

  final int mindfulMinutes;

  /// The day with the most steps; null for a week without any.
  final ActivitySummary? bestDay;

  double get stepsPerDay => days == 0 ? 0 : steps / days;
  double get exercisePerDay => days == 0 ? 0 : exerciseMinutes / days;
  double get kcalPerDay => days == 0 ? 0 : moveKcal / days;
  Duration? get sleepPerNight => sleepNights == 0 ? null : sleep ~/ sleepNights;
  double? get waterPerDay => waterDays == 0 ? null : waterMl / waterDays;
}

/// The week in review: the last seven full days against the seven before,
/// the few things most worth saying about it, and the streaks running.
///
/// Full days, ending yesterday, so the review reads the same all day long
/// and is not dragged down by a morning that has barely started; streaks do
/// count today once its goal is met.
class WeeklyReview {
  const WeeklyReview({
    required this.from,
    required this.to,
    required this.thisWeek,
    required this.lastWeek,
    required this.highlights,
    required this.streaks,
  });

  /// The first and last day of the week reviewed.
  final DateTime from;
  final DateTime to;

  final WeekTotals thisWeek;
  final WeekTotals lastWeek;

  /// Biggest first.
  final List<Highlight> highlights;

  /// Only the ones running.
  final List<Streak> streaks;

  /// Whether there is anything to review at all.
  bool get empty =>
      thisWeek.steps == 0 &&
      thisWeek.workouts == 0 &&
      thisWeek.sleepNights == 0 &&
      thisWeek.waterDays == 0 &&
      thisWeek.mindfulMinutes == 0;

  /// [days] are day summaries oldest first, ending today, at least 14 of
  /// them (more make the streaks longer). The rest are whatever the last
  /// few weeks have: they are sorted into weeks here.
  static WeeklyReview of({
    required List<ActivitySummary> days,
    required List<WorkoutRecord> workouts,
    required List<SleepNight> nights,
    required List<(DateTime, int)> water,
    required List<MindfulSession> mindful,
    required ActivityGoals goals,
    required Duration sleepGoal,
    required int waterGoalMl,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final from = DateTime(today.year, today.month, today.day - 7);
    final before = DateTime(today.year, today.month, today.day - 14);

    WeekTotals totals(DateTime start, DateTime end) {
      bool inside(DateTime t) => !t.isBefore(start) && t.isBefore(end);
      final week = [
        for (final d in days)
          if (inside(d.day)) d,
      ];
      final sessions = [
        for (final w in workouts)
          if (inside(w.start)) w,
      ];
      final slept = [
        for (final n in nights)
          if (inside(n.morning) && n.asleep > Duration.zero) n,
      ];
      final drank = <DateTime, int>{};
      for (final (time, ml) in water) {
        if (!inside(time)) continue;
        final day = DateTime(time.year, time.month, time.day);
        drank[day] = (drank[day] ?? 0) + ml;
      }
      ActivitySummary? best;
      for (final d in week) {
        if (d.steps > 0 && (best == null || d.steps > best.steps)) best = d;
      }
      return WeekTotals(
        days: 7,
        steps: week.fold(0, (t, d) => t + d.steps),
        moveKcal: week.fold(0.0, (t, d) => t + d.activeKcal),
        exerciseMinutes: week.fold(0.0, (t, d) => t + d.exerciseMinutes),
        moveGoalDays: week.where((d) => d.activeKcal >= goals.moveKcal).length,
        stepGoalDays: week.where((d) => d.steps >= goals.steps).length,
        workouts: sessions.length,
        workoutTime: sessions.fold(
          Duration.zero,
          (t, w) => t + w.activeDuration,
        ),
        sleepNights: slept.length,
        sleep: slept.fold(Duration.zero, (t, n) => t + n.asleep),
        waterDays: drank.length,
        waterMl: drank.values.fold(0, (t, ml) => t + ml),
        mindfulMinutes: mindful
            .where((s) => inside(s.start))
            .fold(0, (t, s) => t + s.length.inMinutes),
        bestDay: best,
      );
    }

    final thisWeek = totals(from, today);
    final lastWeek = totals(before, from);

    return WeeklyReview(
      from: from,
      to: DateTime(today.year, today.month, today.day - 1),
      thisWeek: thisWeek,
      lastWeek: lastWeek,
      highlights: _highlights(
        thisWeek,
        lastWeek,
        goals: goals,
        sleepGoal: sleepGoal,
        waterGoalMl: waterGoalMl,
      ),
      streaks: _streaks(days, workouts, goals, today),
    );
  }

  static List<Highlight> _highlights(
    WeekTotals now,
    WeekTotals then, {
    required ActivityGoals goals,
    required Duration sleepGoal,
    required int waterGoalMl,
  }) {
    final out = <Highlight>[];

    // Steps, against the week before.
    if (now.steps > 0) {
      final change = _change(now.stepsPerDay, then.stepsPerDay);
      final perDay = '${_thousands(now.stepsPerDay.round())} steps a day';
      if (change != null && change.abs() >= 0.08) {
        final more = change > 0;
        out.add(
          Highlight(
            kind: HighlightKind.steps,
            title:
                'You walked ${(change.abs() * 100).round()}% '
                '${more ? 'more' : 'less'}',
            detail:
                '$perDay, against '
                '${_thousands(then.stepsPerDay.round())} the week before.',
            trend: more ? Trend.up : Trend.down,
            weight: change.abs() * 3,
          ),
        );
      } else {
        out.add(
          Highlight(
            kind: HighlightKind.steps,
            title: change == null ? perDay : 'As active as last week',
            detail: change == null
                ? 'Your first week of steps.'
                : '$perDay, much as the week before.',
            weight: 0.1,
          ),
        );
      }
    }

    // The Move ring.
    if (now.moveKcal > 0) {
      final days = now.moveGoalDays;
      out.add(
        Highlight(
          kind: HighlightKind.move,
          title: days == 7
              ? 'Move goal every day'
              : days == 0
              ? 'Move goal not reached'
              : 'Move goal on $days of 7 days',
          detail:
              '${now.kcalPerDay.round()} kcal a day, '
              'goal ${goals.moveKcal}.',
          trend: days > then.moveGoalDays
              ? Trend.up
              : days < then.moveGoalDays
              ? Trend.down
              : Trend.steady,
          weight: days == 7 ? 0.9 : (days - then.moveGoalDays).abs() * 0.12,
        ),
      );
    }

    // Workouts.
    if (now.workouts > 0 || then.workouts > 0) {
      final diff = now.workouts - then.workouts;
      final time = _words(now.workoutTime);
      out.add(
        Highlight(
          kind: HighlightKind.workouts,
          title: now.workouts == 0
              ? 'No workouts this week'
              : '${now.workouts} workout${now.workouts == 1 ? '' : 's'}',
          detail: now.workouts == 0
              ? 'There were ${then.workouts} the week before.'
              : diff == 0
              ? '$time in all, as many as the week before.'
              : '$time in all, ${diff.abs()} '
                    '${diff > 0 ? 'more' : 'fewer'} than the week before.',
          trend: diff > 0
              ? Trend.up
              : diff < 0
              ? Trend.down
              : Trend.steady,
          weight: 0.3 + diff.abs() * 0.2,
        ),
      );
    }

    // Sleep, against the goal first, then the week before.
    final slept = now.sleepPerNight;
    if (slept != null) {
      final short = sleepGoal - slept;
      final before = then.sleepPerNight;
      final change = before == null ? null : slept - before;
      final String title;
      final Trend trend;
      double weight;
      if (change != null && change.inMinutes.abs() >= 20) {
        title =
            'You slept ${_words(Duration(minutes: change.inMinutes.abs()))} '
            '${change.isNegative ? 'less' : 'more'} a night';
        trend = change.isNegative ? Trend.down : Trend.up;
        weight = change.inMinutes.abs() / 40;
      } else if (short.inMinutes >= 30) {
        title = 'Short of your sleep goal';
        trend = Trend.down;
        weight = short.inMinutes / 60;
      } else {
        title = 'Sleep on track';
        trend = Trend.steady;
        weight = 0.4;
      }
      out.add(
        Highlight(
          kind: HighlightKind.sleep,
          title: title,
          detail:
              '${_words(slept)} a night over ${now.sleepNights} '
              'night${now.sleepNights == 1 ? '' : 's'}, '
              'goal ${_words(sleepGoal)}.',
          trend: trend,
          weight: weight,
        ),
      );
    }

    // Water.
    final drank = now.waterPerDay;
    if (drank != null) {
      final share = drank / waterGoalMl;
      out.add(
        Highlight(
          kind: HighlightKind.water,
          title: share >= 0.95
              ? 'Well hydrated'
              : 'Water ${(share * 100).round()}% of goal',
          detail:
              '${(drank / 1000).toStringAsFixed(1)} L a day on '
              '${now.waterDays} day${now.waterDays == 1 ? '' : 's'} logged.',
          trend: share >= 0.95 ? Trend.up : Trend.steady,
          weight: share >= 0.95 ? 0.35 : 0.25,
        ),
      );
    }

    // Mindfulness.
    if (now.mindfulMinutes > 0) {
      final diff = now.mindfulMinutes - then.mindfulMinutes;
      out.add(
        Highlight(
          kind: HighlightKind.mindful,
          title: '${now.mindfulMinutes} mindful minutes',
          detail: diff == 0
              ? 'As many as the week before.'
              : '${diff.abs()} ${diff > 0 ? 'more' : 'fewer'} than the '
                    'week before.',
          trend: diff > 0
              ? Trend.up
              : diff < 0
              ? Trend.down
              : Trend.steady,
          weight: 0.2,
        ),
      );
    }

    return out..sort((a, b) => b.weight.compareTo(a.weight));
  }

  static List<Streak> _streaks(
    List<ActivitySummary> days,
    List<WorkoutRecord> workouts,
    ActivityGoals goals,
    DateTime today,
  ) {
    // Days in order, newest last; today counts if it is already done, and
    // otherwise does not break the run.
    (int, int) run(bool Function(ActivitySummary) met) {
      var best = 0, current = 0;
      for (final d in days) {
        current = met(d) ? current + 1 : 0;
        if (current > best) best = current;
      }
      var running = 0;
      for (final d in days.reversed) {
        if (met(d)) {
          running++;
        } else if (d.day == today) {
          continue;
        } else {
          break;
        }
      }
      return (running, best);
    }

    final out = <Streak>[];
    final (move, moveBest) = run((d) => d.activeKcal >= goals.moveKcal);
    if (move >= 2) {
      out.add(
        Streak(
          kind: HighlightKind.move,
          title: 'Move Goal',
          count: move,
          unit: 'days',
          best: moveBest,
        ),
      );
    }
    final (steps, stepsBest) = run((d) => d.steps >= goals.steps);
    if (steps >= 2) {
      out.add(
        Streak(
          kind: HighlightKind.steps,
          title: 'Step Goal',
          count: steps,
          unit: 'days',
          best: stepsBest,
        ),
      );
    }
    final (exercise, exerciseBest) = run(
      (d) => d.exerciseMinutes >= goals.exerciseMinutes,
    );
    if (exercise >= 2) {
      out.add(
        Streak(
          kind: HighlightKind.exercise,
          title: 'Exercise Goal',
          count: exercise,
          unit: 'days',
          best: exerciseBest,
        ),
      );
    }

    // Weeks in a row with a workout in them, Monday to Sunday; this week
    // counts once it has one.
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    int weekOf(DateTime t) {
      final day = DateTime(t.year, t.month, t.day);
      // Rounded, not truncated: a clock change makes a day 23 or 25 hours.
      final days = (sunday.difference(day).inHours / 24).round();
      return days < 0 ? -1 : days ~/ 7;
    }

    final weeks = {for (final w in workouts) weekOf(w.start)}..remove(-1);
    var running = 0;
    for (var i = weeks.contains(0) ? 0 : 1; weeks.contains(i); i++) {
      running++;
    }
    var best = 0, current = 0;
    final last = weeks.isEmpty ? 0 : weeks.reduce((a, b) => a > b ? a : b);
    for (var i = last; i >= 0; i--) {
      current = weeks.contains(i) ? current + 1 : 0;
      if (current > best) best = current;
    }
    if (running >= 2) {
      out.add(
        Streak(
          kind: HighlightKind.workouts,
          title: 'Workout Weeks',
          count: running,
          unit: 'weeks',
          best: best,
        ),
      );
    }
    return out..sort((a, b) => b.count.compareTo(a.count));
  }

  /// The relative change from [before] to [now]; null with nothing before.
  static double? _change(double now, double before) =>
      before <= 0 ? null : (now - before) / before;

  static String _thousands(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static String _words(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }
}
