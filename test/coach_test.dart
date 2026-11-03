import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/coach.dart';

CoachInputs inputs({
  required DateTime now,
  int steps = 10000,
  int stepStreak = 0,
  int? lastNight = 480,
  int? readiness = 70,
  String? planned,
  bool workedOut = false,
  int? daysSinceWorkout = 1,
  bool foodLogged = true,
  double kcalEaten = 1200,
  double proteinEaten = 80,
  int water = 2000,
  int? daysSinceWeighIn = 2,
  bool mindful = true,
  int? mood,
}) => CoachInputs(
  now: now,
  steps: steps,
  stepsGoal: 10000,
  stepStreak: stepStreak,
  ringsClosed: false,
  lastNightMinutes: lastNight,
  sleepGoalMinutes: 480,
  bedtimeMinutes: 23 * 60,
  readiness: readiness,
  plannedTitle: planned,
  plannedMinutes: planned == null ? null : 55,
  workedOutToday: workedOut,
  daysSinceWorkout: daysSinceWorkout,
  foodLogged: foodLogged,
  kcalEaten: kcalEaten,
  kcalBudget: 2200,
  proteinEaten: proteinEaten,
  proteinTarget: 130,
  waterMl: water,
  waterGoalMl: 2500,
  daysSinceWeighIn: daysSinceWeighIn,
  mindfulToday: mindful,
  recentMood: mood,
);

void main() {
  final morning = DateTime(2026, 11, 3, 8, 30);
  final evening = DateTime(2026, 11, 3, 19, 30);

  List<SuggestionKind> kinds(CoachInputs i) => [
    for (final s in Coach.suggest(i)) s.kind,
  ];

  test('a short night comes first in the morning', () {
    final s = Coach.suggest(inputs(now: morning, lastNight: 330));
    expect(s.first.kind, SuggestionKind.sleep);
    expect(s.first.title, 'Short night: 5 hr 30 min');
    expect(s.first.detail, contains('22:30'));
  });

  test('steps in reach in the evening, the streak said', () {
    final s = Coach.suggest(
      inputs(now: evening, steps: 7900, stepStreak: 5),
    ).first;
    expect(s.kind, SuggestionKind.steps);
    expect(s.title, '2,100 steps to go');
    expect(s.detail, contains('5-day streak'));
  });

  test('low readiness says to go easy instead of the planned session', () {
    final s = Coach.suggest(
      inputs(now: morning, readiness: 35, planned: 'Upper A'),
    );
    expect(s.map((e) => e.kind), contains(SuggestionKind.readiness));
    expect(s.map((e) => e.kind), isNot(contains(SuggestionKind.training)));
  });

  test('high readiness and a session planned: push', () {
    final s = Coach.suggest(
      inputs(now: evening, readiness: 88, planned: 'Upper A'),
    ).firstWhere((e) => e.kind == SuggestionKind.training);
    expect(s.title, 'Ready for Upper A');
  });

  test('nothing about training once it is done', () {
    expect(
      kinds(inputs(now: evening, planned: 'Upper A', workedOut: true)),
      isNot(contains(SuggestionKind.training)),
    );
  });

  test('protein behind in the afternoon, with foods to reach it', () {
    final s = Coach.suggest(
      inputs(now: evening, proteinEaten: 40),
    ).firstWhere((e) => e.kind == SuggestionKind.protein);
    expect(s.title, 'Protein is behind: 40 of 130 g');
  });

  test('bedtime close beats everything', () {
    final late = DateTime(2026, 11, 3, 22, 20);
    expect(
      Coach.suggest(
        inputs(now: late, steps: 6000, proteinEaten: 20),
      ).first.kind,
      SuggestionKind.bedtime,
    );
  });

  test('a low mood suggests breathing', () {
    expect(
      kinds(inputs(now: evening, mood: -2, mindful: false)),
      contains(SuggestionKind.mind),
    );
  });

  test('all on track says nothing, and never more than three', () {
    expect(Coach.suggest(inputs(now: DateTime(2026, 11, 3, 13))), isEmpty);
    final busy = Coach.suggest(
      inputs(
        now: evening,
        steps: 6000,
        lastNight: 300,
        planned: 'Lower A',
        proteinEaten: 30,
        water: 200,
        mood: -3,
        mindful: false,
      ),
    );
    expect(busy, hasLength(3));
  });
}
