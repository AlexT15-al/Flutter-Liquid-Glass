import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/notifications.dart';
import 'package:halo/domain/sleep.dart';

void main() {
  // Sunday 1 November, 10:00.
  final now = DateTime(2026, 11, 1, 10);
  const sleep = SleepSchedule(bedtimeMinutes: 23 * 60, wakeMinutes: 7 * 60);

  List<PlannedNotification> plan(
    NotificationSettings settings, {
    Map<int, PlannedDay> training = const {},
  }) => NotificationPlanner.plan(
    settings: settings,
    now: now,
    sleep: sleep,
    training: training,
    stepsGoal: 10000,
    stepStreak: 4,
    waterGoalMl: 2500,
  );

  test('the one switch turns every reminder off', () {
    expect(plan(const NotificationSettings(enabled: false)), isEmpty);
    expect(plan(const NotificationSettings()), isNotEmpty);
  });

  test('each reminder has its own switch; habits start off', () {
    final kinds = {for (final p in plan(const NotificationSettings())) p.kind};
    expect(kinds, contains(NotificationKind.bedtime));
    expect(kinds, isNot(contains(NotificationKind.water)));
    final noBedtime = const NotificationSettings().withKind(
      NotificationKind.bedtime,
      const NotificationSetting(on: false, minutes: 30),
    );
    expect(
      plan(noBedtime).where((p) => p.kind == NotificationKind.bedtime),
      isEmpty,
    );
  });

  test('bedtime comes its lead before, and nothing already past', () {
    final bedtime = plan(
      const NotificationSettings(),
    ).where((p) => p.kind == NotificationKind.bedtime).toList();
    expect(bedtime.first.at, DateTime(2026, 11, 1, 22, 30));
    expect(bedtime, hasLength(NotificationPlanner.days));
    // This morning's summary (07:30) is past at 10:00.
    final summaries = plan(
      const NotificationSettings(),
    ).where((p) => p.kind == NotificationKind.sleepSummary);
    expect(summaries.first.at, DateTime(2026, 11, 2, 7, 30));
  });

  test('a bedtime after midnight is reminded the evening before', () {
    final late = NotificationPlanner.plan(
      settings: const NotificationSettings(),
      now: now,
      sleep: const SleepSchedule(bedtimeMinutes: 30, wakeMinutes: 8 * 60),
      training: const {},
      stepsGoal: 10000,
      stepStreak: 0,
      waterGoalMl: 2500,
    ).firstWhere((p) => p.kind == NotificationKind.bedtime);
    expect(late.at, DateTime(2026, 11, 2, 0, 0));
  });

  test('training days only, at the chosen time, with the session', () {
    final settings = const NotificationSettings().withKind(
      NotificationKind.workout,
      const NotificationSetting(on: true, minutes: 18 * 60),
    );
    final workouts = plan(
      settings,
      training: {
        DateTime.monday: (
          title: 'Upper A',
          length: const Duration(minutes: 55),
        ),
        DateTime.thursday: (
          title: 'Lower A',
          length: const Duration(minutes: 60),
        ),
      },
    ).where((p) => p.kind == NotificationKind.workout).toList();
    expect(workouts.map((p) => p.at), [
      DateTime(2026, 11, 2, 18),
      DateTime(2026, 11, 5, 18),
    ]);
    expect(workouts.first.title, 'Today: Upper A');
    expect(workouts.first.check['type'], 'workout');
  });

  test('the weekly summary on Mondays, the weigh-in on its day', () {
    final all = plan(const NotificationSettings());
    final weekly = all.where((p) => p.kind == NotificationKind.weekly);
    expect(weekly.single.at, DateTime(2026, 11, 2, 9));
    final weigh = all.where((p) => p.kind == NotificationKind.weighIn);
    expect(weigh.single.at.weekday, DateTime.monday);
  });

  test('only today carries the streak into the steps check', () {
    final steps = plan(
      const NotificationSettings(),
    ).where((p) => p.kind == NotificationKind.activity).toList();
    expect(steps.first.check['streak'], 4);
    expect(steps[1].check['streak'], 0);
  });

  test('ids are unique, and settings survive a round trip', () {
    final settings = const NotificationSettings()
        .withKind(
          NotificationKind.water,
          const NotificationSetting(on: true, minutes: 0),
        )
        .withKind(
          NotificationKind.meals,
          const NotificationSetting(on: true, minutes: 0),
        );
    final all = plan(settings);
    expect(all.map((p) => p.id).toSet().length, all.length);

    final back = NotificationSettings.fromJson(settings.toJson());
    expect(back.sends(NotificationKind.water), isTrue);
    expect(back.sends(NotificationKind.mindful), isFalse);
    expect(back.enabled, isTrue);
  });
}
