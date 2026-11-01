import 'dart:math' as math;

import 'body_profile.dart';

/// The meals of a day, in order.
enum Meal {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snacks');

  const Meal(this.title);

  final String title;

  static Meal byName(String name) => Meal.values.asNameMap()[name] ?? snack;

  /// The meal a moment of the day most likely is.
  static Meal at(DateTime time) => switch (time.hour) {
    < 11 => breakfast,
    < 16 => lunch,
    < 22 => dinner,
    _ => snack,
  };
}

/// Something eaten, as logged.
///
/// Calories are optional: a meal logged without them still counts as a meal,
/// and simply adds nothing to the day's energy. When they are there, they
/// count.
class FoodEntry {
  const FoodEntry({
    this.id,
    required this.time,
    required this.meal,
    required this.name,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.portions = 1,
  });

  final int? id;
  final DateTime time;
  final Meal meal;
  final String name;

  /// For all [portions] together.
  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double portions;
}

/// How fast to move towards the target weight.
enum WeightPace {
  gentle('Gentle', 0.25),
  steady('Steady', 0.5),
  brisk('Brisk', 0.75);

  const WeightPace(this.title, this.kgPerWeek);

  final String title;
  final double kgPerWeek;

  static WeightPace byName(String? name) =>
      WeightPace.values.asNameMap()[name] ?? steady;
}

/// The weight the user is working towards, and how fast.
class WeightGoal {
  const WeightGoal({this.targetKg, this.pace = WeightPace.steady});

  /// Null: no target, eat to maintain.
  final double? targetKg;
  final WeightPace pace;

  WeightGoal copyWith({double? targetKg, WeightPace? pace}) =>
      WeightGoal(targetKg: targetKg ?? this.targetKg, pace: pace ?? this.pace);

  Map<String, Object?> toJson() => {'target': targetKg, 'pace': pace.name};

  static WeightGoal fromJson(Map<String, Object?> json) => WeightGoal(
    targetKg: (json['target'] as num?)?.toDouble(),
    pace: WeightPace.byName(json['pace'] as String?),
  );
}

/// What to eat in a day, worked out from the body and the goal.
class NutritionTargets {
  const NutritionTargets({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.waterMl,
    required this.maintenance,
  });

  final int kcal;

  /// Grams.
  final int protein;
  final int carbs;
  final int fat;
  final int waterMl;

  /// What keeps the weight where it is.
  final int maintenance;

  /// Losing, keeping or gaining, from the profile and the goal.
  ///
  /// - Resting energy by Mifflin–St Jeor, times 1.35 for an ordinary day on
  ///   the feet; the activity the rings measure is added on top as the day
  ///   goes, rather than guessed here, but only [exerciseShare] of it (see
  ///   [budget]).
  /// - A kilogram of body fat is about 7,700 kcal, so half a kilogram a week
  ///   is 550 kcal a day less (or more, to gain).
  /// - Never below 1,200 kcal (1,500 for men), which is where under-eating
  ///   starts to cost muscle and health.
  /// - Protein 1.6 g per kg; while losing, 1.8 g per kg of the target
  ///   weight, to keep muscle; at most 35% of the energy. Fat 27% of the
  ///   energy; carbohydrate the rest.
  /// - Water 33 ml per kg, to the nearest glass.
  static NutritionTargets of(
    BodyProfile profile,
    WeightGoal goal, {
    required DateTime today,
  }) {
    final kg = profile.weightKg;
    final age = profile.ageOn(today) ?? 30;
    final sexTerm = switch (profile.sex) {
      BiologicalSex.male => 5.0,
      BiologicalSex.female => -161.0,
      BiologicalSex.unspecified => -78.0,
    };
    final bmr = 10 * kg + 6.25 * profile.heightCm - 5 * age + sexTerm;
    final maintenance = bmr * 1.35;

    final target = goal.targetKg;
    var delta = 0.0;
    if (target != null && (target - kg).abs() >= 0.5) {
      final perDay = goal.pace.kgPerWeek * 7700 / 7;
      // Gaining is held to the gentler paces: faster is mostly fat.
      delta = target < kg ? -perDay : math.min(perDay, 0.5 * 7700 / 7);
    }
    final floor = switch (profile.sex) {
      BiologicalSex.male => 1500.0,
      BiologicalSex.female => 1200.0,
      BiologicalSex.unspecified => 1350.0,
    };
    final kcal = math.max(floor, maintenance + delta);
    final losing = delta < 0;
    // While losing, more protein keeps the muscle, counted on the weight
    // being aimed for: what the fat weighs needs none. Never more than 35%
    // of the energy, which is past what helps.
    final protein = math.min(
      losing ? 1.8 * math.min(kg, target!) : 1.6 * kg,
      kcal * 0.35 / 4,
    );
    final fat = kcal * 0.27 / 9;
    final carbs = math.max(0.0, (kcal - protein * 4 - fat * 9) / 4);
    final water = (kg * 33 / 250).round() * 250;

    return NutritionTargets(
      kcal: (kcal / 10).round() * 10,
      protein: protein.round(),
      carbs: carbs.round(),
      fat: fat.round(),
      waterMl: water.clamp(1500, 4000),
      maintenance: (maintenance / 10).round() * 10,
    );
  }

  /// The share of the day's measured activity that is added to the food
  /// budget.
  ///
  /// Half, for two reasons. The 1.35 above already counts the walking of an
  /// ordinary day, which the rings count again. And without a heart rate the
  /// rings' energy is an estimate that runs high more often than low; eating
  /// it all back is the usual reason a diet stalls.
  static const exerciseShare = 0.5;

  /// The day's calories to eat: the target and half the activity so far.
  int budget(double activeKcal) => (kcal + activeKcal * exerciseShare).round();

  /// Weeks to the target at its pace, if there is one to reach.
  static int? weeksTo(BodyProfile profile, WeightGoal goal) {
    final target = goal.targetKg;
    if (target == null) return null;
    final diff = (target - profile.weightKg).abs();
    if (diff < 0.5) return 0;
    final pace = target < profile.weightKg
        ? goal.pace.kgPerWeek
        : math.min(goal.pace.kgPerWeek, 0.5);
    return (diff / pace).ceil();
  }
}
