import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/body_profile.dart';
import 'package:halo/domain/meal_plan.dart';
import 'package:halo/domain/nutrition.dart';
import 'package:halo/domain/training.dart';
import 'package:halo/domain/warm_up.dart';

void main() {
  const body = BodyProfile(
    heightCm: 178,
    weightKg: 80,
    sex: BiologicalSex.male,
  );
  final today = DateTime(2026, 11, 2); // a Monday

  group('training', () {
    test('three gym days are full body, loads from body weight', () {
      final week = TrainingPlanner.week(
        training: const TrainingProfile(),
        body: body,
        goal: const WeightGoal(),
        history: const [],
      );
      expect(week.map((s) => s.title), [
        'Full Body A',
        'Full Body B',
        'Full Body A',
      ]);
      final squat = week.first.exercises.first;
      expect(squat.exercise.id, 'back_squat');
      expect(squat.kg, 40); // 80 × 0.5, beginner
      expect(squat.sets, 3);
    });

    test('a swapped exercise takes its slot in every session', () {
      final plain = TrainingPlanner.week(
        training: const TrainingProfile(),
        body: body,
        goal: const WeightGoal(),
        history: const [],
      );
      final squat = plain.first.exercises.first;
      expect(squat.slot, 'squat:0');
      final alternatives = ExerciseCatalog.alternatives(squat.exercise);
      expect(alternatives.map((e) => e.id), contains('goblet_squat'));
      expect(alternatives.every((e) => e.pattern == Pattern.squat), isTrue);

      final swapped = TrainingPlanner.week(
        training: const TrainingProfile().swapped('squat:0', 'goblet_squat'),
        body: body,
        goal: const WeightGoal(),
        history: const [],
      );
      // Full Body A is on Monday and Friday: both have the goblet squat.
      for (final s in swapped.where((s) => s.title == 'Full Body A')) {
        final e = s.exercises.first;
        expect(e.exercise.id, 'goblet_squat');
        expect(e.swapped, isTrue);
        expect(e.kg, 15); // 80 × 0.2 = 16, in the 5 kg steps legs move in
      }
      // And back again.
      final back = const TrainingProfile()
          .swapped('squat:0', 'goblet_squat')
          .swapped('squat:0', null);
      expect(back.swaps, isEmpty);
    });

    test('body-weight swaps at the gym climb in reps, without a load', () {
      final week = TrainingPlanner.week(
        training: const TrainingProfile().swapped('pullVertical:0', 'pullup'),
        body: body,
        goal: const WeightGoal(),
        history: const [],
      );
      final pull = week[1].exercises.firstWhere(
        (e) => e.exercise.pattern == Pattern.pullVertical,
      );
      expect(pull.exercise.id, 'pullup');
      expect(pull.kg, isNull);
    });

    test('swaps survive a round trip', () {
      final profile = const TrainingProfile().swapped('hinge:1', 'deadlift');
      final back = TrainingProfile.fromJson(profile.toJson());
      expect(back.swaps, {'hinge:1': 'deadlift'});
    });

    test('warm-up sets climb to the working load, from the bar', () {
      final squat = PlannedExercise(
        exercise: ExerciseCatalog.byId('back_squat'),
        sets: 3,
        min: 8,
        max: 12,
        kg: 80,
      );
      final sets = WarmUp.sets(squat, step: 5);
      expect(sets.first.kg, 20);
      expect(sets.map((s) => s.kg), [20, 30, 50, 65]);
      expect(sets.every((s) => s.kg < 80), isTrue);
      // Light or small lifts need none.
      final curl = PlannedExercise(
        exercise: ExerciseCatalog.byId('db_curl'),
        sets: 3,
        min: 10,
        max: 15,
        kg: 8,
      );
      expect(WarmUp.sets(curl), isEmpty);
    });

    test('the general warm-up suits the session', () {
      final week = TrainingPlanner.week(
        training: TrainingProfile(weekdays: TrainingProfile.defaultDays(4)),
        body: body,
        goal: const WeightGoal(),
        history: const [],
      );
      final upper = WarmUp.general(week.first, TrainingPlace.gym);
      expect(upper.map((m) => m.name), contains('Arm circles'));
      expect(upper.map((m) => m.name), isNot(contains('Leg swings')));
      final lower = WarmUp.general(week[1], TrainingPlace.gym);
      expect(lower.map((m) => m.name), contains('Leg swings'));
    });

    test('four days split upper and lower; losing adds a finisher', () {
      final week = TrainingPlanner.week(
        training: TrainingProfile(weekdays: TrainingProfile.defaultDays(4)),
        body: body,
        goal: const WeightGoal(targetKg: 74),
        history: const [],
      );
      expect(week.map((s) => s.title).toList(), [
        'Upper A',
        'Lower A',
        'Upper B',
        'Lower B',
      ]);
      expect(
        week.every(
          (s) => s.exercises.last.exercise.pattern == Pattern.conditioning,
        ),
        isTrue,
      );
    });

    List<SetLog> session(DateTime t, String id, double kg, List<int> reps) => [
      for (final r in reps) SetLog(time: t, exerciseId: id, reps: r, kg: kg),
    ];

    PlannedExercise squatAfter(List<SetLog> history) => TrainingPlanner.week(
      training: const TrainingProfile(),
      body: body,
      goal: const WeightGoal(),
      history: history,
    ).first.exercises.first;

    test('all sets at the top of the range: the load goes up', () {
      final next = squatAfter(session(today, 'back_squat', 60, [12, 12, 12]));
      expect(next.kg, 65);
      expect(next.change, 5);
    });

    test('in range: the same load, more reps', () {
      final next = squatAfter(session(today, 'back_squat', 60, [12, 10, 9]));
      expect(next.kg, 60);
    });

    test('short of the range twice running: the load comes down', () {
      final next = squatAfter([
        ...session(today, 'back_squat', 60, [8, 6, 5]),
        ...session(today.subtract(const Duration(days: 3)), 'back_squat', 60, [
          7,
          6,
          6,
        ]),
      ]);
      expect(next.kg, 55);
      expect(next.change, -5);
    });

    test('at home, mastering an exercise moves up the ladder', () {
      const home = TrainingProfile(place: TrainingPlace.home);
      PlannedExercise push(List<SetLog> history) => TrainingPlanner.week(
        training: home,
        body: body,
        goal: const WeightGoal(),
        history: history,
      ).first.exercises[1];
      expect(push(const []).exercise.id, 'incline_pushup');
      expect(
        push(session(today, 'incline_pushup', 0, [15, 15, 15])).exercise.id,
        'pushup',
      );
      expect(
        push(session(today, 'incline_pushup', 0, [15, 12, 10])).exercise.id,
        'incline_pushup',
      );
    });
  });

  group('meals', () {
    final targets = NutritionTargets.of(body, const WeightGoal(), today: today);

    test('a day adds up to about its calories', () {
      final day = MealPlanner.day(today, targets, const MealPlanSettings());
      final kcal = day.fold<double>(0, (t, m) => t + m.kcal);
      expect(kcal, closeTo(targets.kcal, targets.kcal * 0.12));
      expect(day.map((m) => m.meal), Meal.values);
    });

    test('a losing week reaches its protein, a day at a time', () {
      final losing = NutritionTargets.of(
        body,
        WeightGoal(targetKg: body.weightKg - 8),
        today: today,
      );
      var total = 0.0;
      for (var d = 0; d < 28; d++) {
        final day = MealPlanner.day(
          today.add(Duration(days: d)),
          losing,
          const MealPlanSettings(),
        );
        final protein = day.fold<double>(0, (t, m) => t + m.protein);
        final kcal = day.fold<double>(0, (t, m) => t + m.kcal);
        expect(protein, greaterThan(losing.protein * 0.85));
        expect(kcal, closeTo(losing.kcal, losing.kcal * 0.12));
        total += protein;
      }
      expect(total / 28, greaterThanOrEqualTo(losing.protein * 0.95));
    });

    test('a big lunch makes the rest of the day lighter', () {
      final full = MealPlanner.day(today, targets, const MealPlanSettings());
      final dinnerBefore = full.firstWhere((m) => m.meal == Meal.dinner);
      final adapted = MealPlanner.day(
        today,
        targets,
        const MealPlanSettings(),
        eaten: {
          Meal.breakfast: const MealIntake(kcal: 500, protein: 25),
          Meal.lunch: MealIntake(kcal: targets.kcal * 0.55, protein: 40),
        },
      );
      // Only what is still to come is planned.
      expect(adapted.map((m) => m.meal), [Meal.dinner, Meal.snack]);
      final dinner = adapted.firstWhere((m) => m.meal == Meal.dinner);
      expect(dinner.kcal, lessThan(dinnerBefore.kcal));
      // The day still comes to about its calories.
      final day =
          500 +
          targets.kcal * 0.55 +
          adapted.fold<double>(0, (t, m) => t + m.kcal);
      expect(day, closeTo(targets.kcal, targets.kcal * 0.15));
    });

    test('over budget, the meals left are light but still planned', () {
      final adapted = MealPlanner.day(
        today,
        targets,
        const MealPlanSettings(),
        eaten: {
          Meal.breakfast: MealIntake(kcal: targets.kcal * 1.2, protein: 30),
        },
      );
      expect(adapted, hasLength(3));
      final left = adapted.fold<double>(0, (t, m) => t + m.kcal);
      // Half of their usual 75% of the day, near enough.
      expect(left, closeTo(targets.kcal * 0.75 * 0.5, targets.kcal * 0.15));
    });

    test('fasting days plan only lenten food', () {
      const settings = MealPlanSettings(fastingWeekdays: {3, 5});
      final wednesday = today.add(const Duration(days: 2));
      final plan = MealPlanner.day(wednesday, targets, settings);
      expect(plan.every((m) => m.item.lenten), isTrue);
      final lent = MealPlanner.day(
        today,
        targets,
        const MealPlanSettings(lent: true),
      );
      expect(lent.every((m) => m.item.lenten), isTrue);
    });

    test('the same date gives the same plan; a swap changes one meal', () {
      const settings = MealPlanSettings();
      final a = MealPlanner.day(today, targets, settings);
      final b = MealPlanner.day(today, targets, settings);
      expect(a.map((m) => m.item.name), b.map((m) => m.item.name));
      final swapped = MealPlanner.day(
        today,
        targets,
        settings.swapped(today, Meal.lunch),
      );
      expect(swapped[1].item.name, isNot(a[1].item.name));
      expect(swapped[0].item.name, a[0].item.name);
      final tomorrow = MealPlanner.day(
        today.add(const Duration(days: 1)),
        targets,
        settings,
      );
      expect(tomorrow[1].item.name, isNot(a[1].item.name));
    });
  });
}
