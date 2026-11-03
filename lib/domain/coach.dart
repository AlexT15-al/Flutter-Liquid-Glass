/// What a suggestion is about: sets its glyph, colour and where it goes.
enum SuggestionKind {
  sleep('sleep'),
  bedtime('sleep'),
  readiness('readiness'),
  training('training'),
  workout('workout'),
  steps('steps'),
  protein('nutrition'),
  calories('nutrition'),
  log('nutrition'),
  water('water'),
  weigh('weight'),
  mind('breathe'),
  rings('steps');

  const SuggestionKind(this.route);

  /// The screen it opens.
  final String route;
}

class Suggestion {
  const Suggestion({
    required this.kind,
    required this.title,
    required this.detail,
    required this.priority,
  });

  final SuggestionKind kind;
  final String title;
  final String detail;

  /// Higher first.
  final int priority;
}

/// Everything the suggestions are drawn from, as it stands now.
class CoachInputs {
  const CoachInputs({
    required this.now,
    required this.steps,
    required this.stepsGoal,
    required this.stepStreak,
    required this.ringsClosed,
    this.lastNightMinutes,
    required this.sleepGoalMinutes,
    required this.bedtimeMinutes,
    this.readiness,
    this.plannedTitle,
    this.plannedMinutes,
    required this.workedOutToday,
    this.daysSinceWorkout,
    required this.foodLogged,
    required this.kcalEaten,
    required this.kcalBudget,
    required this.proteinEaten,
    required this.proteinTarget,
    required this.waterMl,
    required this.waterGoalMl,
    this.daysSinceWeighIn,
    required this.mindfulToday,
    this.recentMood,
  });

  final DateTime now;

  final int steps;
  final int stepsGoal;

  /// Days in a row up to yesterday with the step goal met.
  final int stepStreak;

  /// Move, Exercise and Active Hours all done today.
  final bool ringsClosed;

  /// Last night's time asleep; null when there is no night for this
  /// morning.
  final int? lastNightMinutes;
  final int sleepGoalMinutes;
  final int bedtimeMinutes;

  /// 0 to 100; null without enough data.
  final int? readiness;

  /// Today's session in the plan, if there is one.
  final String? plannedTitle;
  final int? plannedMinutes;
  final bool workedOutToday;

  /// Null with no workout ever.
  final int? daysSinceWorkout;

  final bool foodLogged;
  final double kcalEaten;
  final double kcalBudget;
  final double proteinEaten;
  final double proteinTarget;

  final int waterMl;
  final int waterGoalMl;

  /// Null when never weighed.
  final int? daysSinceWeighIn;

  final bool mindfulToday;

  /// The latest mood of today or yesterday, -3 to 3.
  final int? recentMood;
}

/// Suggestions for right now, from everything Halo knows: the few that
/// matter most at this time of day, most important first.
///
/// Each rule looks at one thing and says something only when there is
/// something worth doing about it; the time of day decides how much it
/// matters (steps in the evening, sleep in the morning, protein by dinner).
abstract final class Coach {
  static List<Suggestion> suggest(CoachInputs i, {int count = 3}) {
    final out = <Suggestion>[];
    final hour = i.now.hour + i.now.minute / 60;
    final minuteOfDay = i.now.hour * 60 + i.now.minute;

    // Bedtime is close.
    final toBed = (i.bedtimeMinutes - minuteOfDay) % (24 * 60);
    if (toBed > 0 && toBed <= 75) {
      out.add(
        Suggestion(
          kind: SuggestionKind.bedtime,
          title: 'Bedtime in ${_minutes(toBed)}',
          detail:
              'Start winding down: screens away, lights low, for '
              '${_hm(i.sleepGoalMinutes)} of sleep.',
          priority: 90,
        ),
      );
    }

    // A short night.
    final slept = i.lastNightMinutes;
    if (slept != null && slept < i.sleepGoalMinutes - 45 && hour < 21) {
      final earlier = (i.bedtimeMinutes - 30) % (24 * 60);
      out.add(
        Suggestion(
          kind: SuggestionKind.sleep,
          title: 'Short night: ${_hm(slept)}',
          detail: 'Try to be in bed by ${_clock(earlier)} tonight to catch up.',
          priority: hour < 12 ? 80 : 62,
        ),
      );
    }

    // Training, as readiness allows.
    final readiness = i.readiness;
    final planned = i.plannedTitle;
    if (!i.workedOutToday) {
      if (readiness != null && readiness < 45) {
        out.add(
          Suggestion(
            kind: SuggestionKind.readiness,
            title: 'Take it easy today',
            detail:
                'Readiness is $readiness. A walk or some yoga will do '
                'more good than hard training${planned == null ? '' : ': '
                          'move $planned to tomorrow'}.',
            priority: 76,
          ),
        );
      } else if (planned != null) {
        final strong = readiness != null && readiness >= 75;
        out.add(
          Suggestion(
            kind: SuggestionKind.training,
            title: strong ? 'Ready for $planned' : 'Today: $planned',
            detail: strong
                ? 'Readiness is $readiness: a good day to push the loads.'
                : 'About ${_minutes(i.plannedMinutes ?? 45)}. Your loads are '
                      'ready in Plans.',
            priority: hour >= 11 ? 74 : 64,
          ),
        );
      } else if ((i.daysSinceWorkout ?? 0) >= 4) {
        out.add(
          Suggestion(
            kind: SuggestionKind.workout,
            title: '${i.daysSinceWorkout} days since your last workout',
            detail: 'A 20-minute walk or run gets you going again.',
            priority: 52,
          ),
        );
      }
    }

    // Steps, later in the day.
    final left = i.stepsGoal - i.steps;
    if (hour >= 15 && left > 0 && left <= 6000) {
      final streak = i.stepStreak >= 2;
      out.add(
        Suggestion(
          kind: SuggestionKind.steps,
          title: '${_thousands(left)} steps to go',
          detail:
              'About ${_minutes((left / 100).ceil())} of walking closes it'
              '${streak ? ' and keeps your ${i.stepStreak}-day streak' : ''}.',
          priority: (streak ? 78 : 66) + (hour >= 19 ? 6 : 0),
        ),
      );
    }

    // Food.
    if (!i.foodLogged && hour >= 13 && hour < 22) {
      out.add(
        const Suggestion(
          kind: SuggestionKind.log,
          title: 'Nothing logged yet today',
          detail:
              'Log what you have eaten, and the rest of today’s plan '
              'adapts to it.',
          priority: 44,
        ),
      );
    } else if (i.foodLogged) {
      final over = i.kcalEaten - i.kcalBudget;
      if (over > 150) {
        out.add(
          Suggestion(
            kind: SuggestionKind.calories,
            title: 'Over today’s calories by ${_thousands(over.round())}',
            detail:
                'A light dinner and a walk keep the week on track; '
                'one day does not undo it.',
            priority: 50,
          ),
        );
      } else if (hour >= 15 && i.proteinEaten < i.proteinTarget * 0.5) {
        out.add(
          Suggestion(
            kind: SuggestionKind.protein,
            title:
                'Protein is behind: ${i.proteinEaten.round()} of '
                '${i.proteinTarget.round()} g',
            detail:
                'Make dinner rich in it: chicken, fish, eggs, lentils, '
                'Greek yogurt.',
            priority: 56,
          ),
        );
      }
    }

    // Water, against the day so far (from 08:00 to 20:00).
    if (hour >= 11 && hour < 21) {
      final expected = i.waterGoalMl * ((hour - 8) / 12).clamp(0.0, 1.0);
      if (i.waterMl < expected * 0.6) {
        out.add(
          Suggestion(
            kind: SuggestionKind.water,
            title: 'Have some water',
            detail:
                '${_litres(i.waterMl)} of ${_litres(i.waterGoalMl)} so '
                'far today.',
            priority: 42,
          ),
        );
      }
    }

    // Weighing in.
    final weighed = i.daysSinceWeighIn;
    if ((weighed == null || weighed >= 7) && hour < 12) {
      out.add(
        Suggestion(
          kind: SuggestionKind.weigh,
          title: 'Time to weigh in',
          detail: weighed == null
              ? 'Before breakfast is best: it starts the trend your plan '
                    'follows.'
              : 'Last time was $weighed days ago. Before breakfast is best.',
          priority: 40,
        ),
      );
    }

    // Mood.
    final mood = i.recentMood;
    if (mood != null && mood <= -2 && !i.mindfulToday) {
      out.add(
        const Suggestion(
          kind: SuggestionKind.mind,
          title: 'A minute to breathe',
          detail:
              'You logged feeling low. A short Breathe session can '
              'settle things.',
          priority: 58,
        ),
      );
    } else if (!i.mindfulToday && hour >= 20 && toBed > 75) {
      out.add(
        const Suggestion(
          kind: SuggestionKind.mind,
          title: 'Wind down with Breathe',
          detail: 'Two minutes of slow breathing before bed helps you settle.',
          priority: 28,
        ),
      );
    }

    // Everything done.
    if (i.ringsClosed) {
      out.add(
        const Suggestion(
          kind: SuggestionKind.rings,
          title: 'All rings closed',
          detail:
              'Move, Exercise and Active Hours are done for today. '
              'Well done.',
          priority: 35,
        ),
      );
    }

    out.sort((a, b) => b.priority.compareTo(a.priority));
    return out.take(count).toList();
  }

  static String _minutes(int m) {
    if (m < 60) return '$m minutes';
    return _hm(m);
  }

  static String _hm(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  static String _litres(int ml) => '${(ml / 1000).toStringAsFixed(1)} L';

  static String _thousands(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
