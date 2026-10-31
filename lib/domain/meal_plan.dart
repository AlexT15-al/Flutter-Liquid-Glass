import 'dart:math' as math;

import 'food_catalog.dart';
import 'nutrition.dart';

/// Which days are fasting days, and how planned meals were swapped.
class MealPlanSettings {
  const MealPlanSettings({
    this.fastingWeekdays = const {},
    this.lent = false,
    this.rerolls = const {},
  });

  /// 1 Monday … 7 Sunday: Wednesdays and Fridays, for the usual Orthodox
  /// fast.
  final Set<int> fastingWeekdays;

  /// A fasting period, such as Lent: every day is a fasting day.
  final bool lent;

  /// How many times a day's meal was swapped, by `yyyy-mm-dd:meal`.
  final Map<String, int> rerolls;

  bool fasting(DateTime day) => lent || fastingWeekdays.contains(day.weekday);

  int rerollsOf(DateTime day, Meal meal) => rerolls[_key(day, meal)] ?? 0;

  MealPlanSettings swapped(DateTime day, Meal meal) => copyWith(
    rerolls: {...rerolls, _key(day, meal): rerollsOf(day, meal) + 1},
  );

  MealPlanSettings copyWith({
    Set<int>? fastingWeekdays,
    bool? lent,
    Map<String, int>? rerolls,
  }) => MealPlanSettings(
    fastingWeekdays: fastingWeekdays ?? this.fastingWeekdays,
    lent: lent ?? this.lent,
    rerolls: rerolls ?? this.rerolls,
  );

  static String _key(DateTime day, Meal meal) =>
      '${day.year}-${day.month}-${day.day}:${meal.name}';

  Map<String, Object?> toJson() => {
    'fasting': (fastingWeekdays.toList()..sort()),
    'lent': lent,
    // Only the swaps of the last few weeks are worth keeping.
    'rerolls': rerolls,
  };

  static MealPlanSettings fromJson(Map<String, Object?> json) =>
      MealPlanSettings(
        fastingWeekdays: {
          for (final d in (json['fasting'] as List?) ?? const [])
            (d as num).toInt(),
        },
        lent: json['lent'] as bool? ?? false,
        rerolls: {
          for (final e in ((json['rerolls'] as Map?) ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
      );
}

/// One planned meal: a food and how much of it.
class PlannedMeal {
  const PlannedMeal({
    required this.meal,
    required this.item,
    required this.portions,
  });

  final Meal meal;
  final FoodItem item;
  final double portions;

  double get kcal => item.kcal * portions;
  double get protein => item.protein * portions;
}

/// A day of meals that adds up to the day's calories.
///
/// The day's energy is split 25% breakfast, 35% lunch, 30% dinner and 10%
/// snacks. Each meal is a dish from the catalogue that suits it, sized in
/// quarter portions to its share; fasting days choose only lenten dishes.
/// The choice is fixed for a date (the same plan every time it is opened)
/// but differs from the day before, and a swap moves to the next dish.
abstract final class MealPlanner {
  static const shares = {
    Meal.breakfast: 0.25,
    Meal.lunch: 0.35,
    Meal.dinner: 0.30,
    Meal.snack: 0.10,
  };

  static List<PlannedMeal> day(
    DateTime date,
    NutritionTargets targets,
    MealPlanSettings settings,
  ) {
    final fasting = settings.fasting(date);
    return [
      for (final meal in Meal.values)
        _pick(date, meal, targets.kcal * shares[meal]!, fasting, settings),
    ];
  }

  static PlannedMeal _pick(
    DateTime date,
    Meal meal,
    double kcal,
    bool fasting,
    MealPlanSettings settings,
  ) {
    final suitable = FoodCatalog.all
        .where((f) => f.meals.contains(meal) && (!fasting || f.lenten))
        .toList();
    // Dishes that fit the meal at a sensible size: not two and a half boiled
    // eggs for a breakfast, not half a moussaka for one.
    final sized = suitable
        .where((f) => kcal / f.kcal >= 0.75 && kcal / f.kcal <= 1.75)
        .toList();
    // Too few that fit: the dishes closest to the size wanted.
    final options = sized.length >= 3
        ? sized
        : ([...suitable]..sort(
                (a, b) => (math.log(
                  kcal / a.kcal,
                )).abs().compareTo((math.log(kcal / b.kcal)).abs()),
              ))
              .take(4)
              .toList();
    // Days since a fixed Monday: consecutive days land on different dishes.
    final dayNumber = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(2024, 1, 1)).inDays;
    final index =
        (dayNumber * 7 + meal.index * 3 + settings.rerollsOf(date, meal)) %
        options.length;
    final item = options[index];
    final portions = ((kcal / item.kcal) * 4).round() / 4;
    return PlannedMeal(
      meal: meal,
      item: item,
      portions: portions.clamp(0.5, 2.0),
    );
  }
}
