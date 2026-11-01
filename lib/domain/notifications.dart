import 'sleep.dart';

/// Each kind of reminder Halo can send.
enum NotificationKind {
  sleepSummary(
    title: 'Sleep Summary',
    detail: 'In the morning, once you pick up your phone.',
    on: true,
    time: NotificationTime.none,
    route: 'sleep',
  ),
  bedtime(
    title: 'Bedtime',
    detail: 'Before the bedtime in your sleep schedule.',
    on: true,
    time: NotificationTime.lead,
    minutes: 30,
    route: 'sleep',
  ),
  workout(
    title: 'Training Days',
    detail: 'The day’s session from your plan, if not done yet.',
    on: true,
    time: NotificationTime.daily,
    minutes: 17 * 60 + 30,
    route: 'training',
  ),
  activity(
    title: 'Steps and Streaks',
    detail:
        'In the evening, when the step goal is in reach or a streak '
        'would end.',
    on: true,
    time: NotificationTime.daily,
    minutes: 19 * 60,
    route: 'steps',
  ),
  weekly(
    title: 'Weekly Summary',
    detail: 'Monday morning: the last seven days and their highlights.',
    on: true,
    time: NotificationTime.daily,
    minutes: 9 * 60,
    route: 'weekly',
  ),
  weighIn(
    title: 'Weigh-In',
    detail: 'Once a week, in the morning, if you have not weighed in.',
    on: true,
    time: NotificationTime.weekly,
    minutes: 8 * 60,
    route: 'weight',
  ),
  water(
    title: 'Water',
    detail: 'At most three times a day, and only when behind.',
    on: false,
    time: NotificationTime.none,
    route: 'water',
  ),
  meals(
    title: 'Log Meals',
    detail: 'After lunch and dinner, if they are not logged.',
    on: false,
    time: NotificationTime.none,
    route: 'nutrition',
  ),
  mindful(
    title: 'Mindfulness',
    detail: 'A minute to breathe, if you have not today.',
    on: false,
    time: NotificationTime.daily,
    minutes: 20 * 60 + 30,
    route: 'breathe',
  );

  const NotificationKind({
    required this.title,
    required this.detail,
    required this.on,
    required this.time,
    this.minutes = 0,
    required this.route,
  });

  final String title;
  final String detail;

  /// On for a new install.
  final bool on;

  /// What the user can set about when it comes.
  final NotificationTime time;

  /// The default time of day in minutes, or for [NotificationTime.lead],
  /// how long before.
  final int minutes;

  /// Where a tap on it opens.
  final String route;
}

/// What can be set about a reminder's time.
enum NotificationTime {
  /// Nothing: it follows something else (waking up, meals).
  none,

  /// A time of day.
  daily,

  /// A day of the week and a time.
  weekly,

  /// How long before an event.
  lead,
}

/// One reminder's settings.
class NotificationSetting {
  const NotificationSetting({
    required this.on,
    required this.minutes,
    this.weekday = DateTime.monday,
  });

  final bool on;
  final int minutes;
  final int weekday;

  NotificationSetting copyWith({bool? on, int? minutes, int? weekday}) =>
      NotificationSetting(
        on: on ?? this.on,
        minutes: minutes ?? this.minutes,
        weekday: weekday ?? this.weekday,
      );
}

/// Every reminder's settings, and the one switch over all of them.
class NotificationSettings {
  const NotificationSettings({this.enabled = true, this.kinds = const {}});

  /// Off: nothing is sent, whatever each reminder says.
  final bool enabled;

  /// Only the ones changed from their defaults.
  final Map<NotificationKind, NotificationSetting> kinds;

  NotificationSetting of(NotificationKind kind) =>
      kinds[kind] ?? NotificationSetting(on: kind.on, minutes: kind.minutes);

  /// Whether [kind] is sent: on, with notifications on.
  bool sends(NotificationKind kind) => enabled && of(kind).on;

  NotificationSettings copyWith({bool? enabled}) =>
      NotificationSettings(enabled: enabled ?? this.enabled, kinds: kinds);

  NotificationSettings withKind(
    NotificationKind kind,
    NotificationSetting setting,
  ) => NotificationSettings(enabled: enabled, kinds: {...kinds, kind: setting});

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'kinds': {
      for (final e in kinds.entries)
        e.key.name: {
          'on': e.value.on,
          'minutes': e.value.minutes,
          'weekday': e.value.weekday,
        },
    },
  };

  static NotificationSettings fromJson(Map<String, Object?> json) {
    final byName = NotificationKind.values.asNameMap();
    final kinds = <NotificationKind, NotificationSetting>{};
    for (final e in ((json['kinds'] as Map?) ?? const {}).entries) {
      final kind = byName[e.key];
      if (kind == null) continue;
      final v = (e.value as Map).cast<String, Object?>();
      kinds[kind] = NotificationSetting(
        on: v['on'] as bool? ?? kind.on,
        minutes: (v['minutes'] as num?)?.toInt() ?? kind.minutes,
        weekday: (v['weekday'] as num?)?.toInt() ?? DateTime.monday,
      );
    }
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      kinds: kinds,
    );
  }
}

/// One reminder to come: when, what it says, and what the phone checks
/// just before showing it.
///
/// The check is done at the time, with the app closed, so a reminder that
/// no longer has anything to say is not shown: the session done, the goal
/// reached, the water drunk.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
    this.check = const {'type': 'none'},
  });

  final int id;
  final NotificationKind kind;
  final DateTime at;
  final String title;
  final String body;
  final Map<String, Object?> check;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'channel': kind.title,
    'at': at.millisecondsSinceEpoch,
    'title': title,
    'body': body,
    'route': kind.route,
    'check': check,
  };
}

/// A training day as the plan has it.
typedef PlannedDay = ({String title, Duration length});

/// Works out the reminders of the next days from the settings and the plans.
///
/// A week at a time: the app plans again every time it opens and whenever
/// something they depend on changes.
abstract final class NotificationPlanner {
  static const days = 7;

  /// Water: when, and how much of the day's goal should be in by then.
  static const waterSlots = [(11 * 60, 0.3), (14 * 60, 0.55), (17 * 60, 0.75)];

  /// Meals: when to ask after lunch and dinner.
  static const mealSlots = [(15 * 60, 'lunch'), (21 * 60 + 30, 'dinner')];

  static List<PlannedNotification> plan({
    required NotificationSettings settings,
    required DateTime now,
    required SleepSchedule sleep,
    required Map<int, PlannedDay> training,
    required int stepsGoal,
    required int stepStreak,
    required int waterGoalMl,
    String? weeklyHeadline,
  }) {
    if (!settings.enabled) return const [];
    final out = <PlannedNotification>[];
    final today = DateTime(now.year, now.month, now.day);

    void add(
      NotificationKind kind,
      int day,
      int slot,
      DateTime at,
      String title,
      String body, [
      Map<String, Object?> check = const {'type': 'none'},
    ]) {
      if (!at.isAfter(now)) return;
      out.add(
        PlannedNotification(
          id: kind.index * 1000 + day * 10 + slot,
          kind: kind,
          at: at,
          title: title,
          body: body,
          check: check,
        ),
      );
    }

    for (var d = 0; d < days; d++) {
      final date = DateTime(today.year, today.month, today.day + d);
      DateTime at(int minutes) =>
          DateTime(date.year, date.month, date.day, 0, minutes);

      if (settings.sends(NotificationKind.sleepSummary)) {
        // First looked for half an hour after the usual wake time; the phone
        // keeps looking until the night has ended.
        add(
          NotificationKind.sleepSummary,
          d,
          0,
          at(sleep.wakeMinutes + 30),
          'Good Morning',
          'See how you slept last night.',
          {'type': 'sleep'},
        );
      }

      if (settings.sends(NotificationKind.bedtime)) {
        final lead = settings.of(NotificationKind.bedtime).minutes;
        var minutes = sleep.bedtimeMinutes - lead;
        // A bedtime after midnight belongs to the evening before.
        if (sleep.bedtimeMinutes < 12 * 60) minutes += 24 * 60;
        add(
          NotificationKind.bedtime,
          d,
          0,
          at(minutes),
          'Bedtime in $lead Minutes',
          'Wind down for ${_words(sleep.goal)} of sleep, up at '
              '${_clock(sleep.wakeMinutes)}.',
        );
      }

      final session = training[date.weekday];
      if (session != null && settings.sends(NotificationKind.workout)) {
        add(
          NotificationKind.workout,
          d,
          0,
          at(settings.of(NotificationKind.workout).minutes),
          'Today: ${session.title}',
          'About ${_words(session.length)}. Your loads are ready in Plans.',
          {'type': 'workout'},
        );
      }

      if (settings.sends(NotificationKind.activity)) {
        add(
          NotificationKind.activity,
          d,
          0,
          at(settings.of(NotificationKind.activity).minutes),
          'Steps',
          '',
          {
            'type': 'steps',
            'goal': stepsGoal,
            // Through yesterday: only today's own plan knows it is running.
            'streak': d == 0 ? stepStreak : 0,
          },
        );
      }

      if (settings.sends(NotificationKind.weekly) &&
          date.weekday == DateTime.monday) {
        add(
          NotificationKind.weekly,
          d,
          0,
          at(settings.of(NotificationKind.weekly).minutes),
          'Your Week',
          d == 0 && weeklyHeadline != null
              ? '$weeklyHeadline. See the highlights and your streaks.'
              : 'The last seven days are in: highlights, streaks and how '
                    'they compare.',
        );
      }

      final weigh = settings.of(NotificationKind.weighIn);
      if (settings.sends(NotificationKind.weighIn) &&
          date.weekday == weigh.weekday) {
        add(
          NotificationKind.weighIn,
          d,
          0,
          at(weigh.minutes),
          'Weigh-In',
          'Before breakfast, for the truest trend.',
          {'type': 'weigh'},
        );
      }

      if (settings.sends(NotificationKind.water)) {
        for (var i = 0; i < waterSlots.length; i++) {
          final (minutes, share) = waterSlots[i];
          add(NotificationKind.water, d, i, at(minutes), 'Water', '', {
            'type': 'water',
            'goal': waterGoalMl,
            'share': share,
          });
        }
      }

      if (settings.sends(NotificationKind.meals)) {
        for (var i = 0; i < mealSlots.length; i++) {
          final (minutes, meal) = mealSlots[i];
          add(
            NotificationKind.meals,
            d,
            i,
            at(minutes),
            'Log Your ${meal == 'lunch' ? 'Lunch' : 'Dinner'}',
            'A quick log keeps today’s calories and protein right.',
            {'type': 'meal', 'meal': meal},
          );
        }
      }

      if (settings.sends(NotificationKind.mindful)) {
        add(
          NotificationKind.mindful,
          d,
          0,
          at(settings.of(NotificationKind.mindful).minutes),
          'A Minute to Breathe',
          'Four seconds in, six out. One minute is enough.',
          {'type': 'mindful'},
        );
      }
    }
    return out..sort((a, b) => a.at.compareTo(b.at));
  }

  static String _clock(int minutes) {
    final m = minutes % (24 * 60);
    return '${(m ~/ 60).toString().padLeft(2, '0')}:'
        '${(m % 60).toString().padLeft(2, '0')}';
  }

  static String _words(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }
}
