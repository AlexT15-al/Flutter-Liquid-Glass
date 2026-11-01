import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/body_profile.dart';
import 'package:halo/domain/food_catalog.dart';
import 'package:halo/domain/nutrition.dart';

void main() {
  final today = DateTime(2026, 10, 31);
  final man = BodyProfile(
    heightCm: 180,
    weightKg: 85,
    birthDate: DateTime(1991, 5, 1),
    sex: BiologicalSex.male,
  );

  test('maintenance from Mifflin–St Jeor on an ordinary day', () {
    final t = NutritionTargets.of(man, const WeightGoal(), today: today);
    // BMR = 10·85 + 6.25·180 − 5·35 + 5 = 1805; × 1.35 ≈ 2437.
    expect(t.maintenance, closeTo(2440, 10));
    expect(t.kcal, t.maintenance);
    expect(t.waterMl, 2750);
  });

  test('losing half a kilo a week is 550 kcal a day less, protein up', () {
    final t = NutritionTargets.of(
      man,
      const WeightGoal(targetKg: 78),
      today: today,
    );
    expect(t.kcal, closeTo(t.maintenance - 550, 10));
    // 1.8 g for each kilogram of the 78 aimed for.
    expect(t.protein, 140);
    expect(NutritionTargets.weeksTo(man, const WeightGoal(targetKg: 78)), 14);
  });

  test('half the measured activity goes into the budget', () {
    final t = NutritionTargets.of(man, const WeightGoal(), today: today);
    expect(t.budget(0), t.kcal);
    expect(t.budget(400), t.kcal + 200);
  });

  test('never below the floor, and gaining is held to a gentle pace', () {
    const small = BodyProfile(
      heightCm: 155,
      weightKg: 48,
      sex: BiologicalSex.female,
    );
    final lose = NutritionTargets.of(
      small,
      const WeightGoal(targetKg: 44, pace: WeightPace.brisk),
      today: today,
    );
    expect(lose.kcal, 1200);
    final gain = NutritionTargets.of(
      man,
      const WeightGoal(targetKg: 95, pace: WeightPace.brisk),
      today: today,
    );
    expect(gain.kcal, closeTo(gain.maintenance + 550, 10));
  });

  test('the catalogue finds foods by any word, best match first', () {
    final hits = FoodCatalog.search('souvlaki');
    expect(hits.first.name, startsWith('Chicken souvlaki'));
    expect(FoodCatalog.search('greek yogurt').length, greaterThanOrEqualTo(2));
    expect(FoodCatalog.search('zzz'), isEmpty);
  });

  test('portions scale everything a food brings', () {
    final item = FoodCatalog.search('fasolada').single;
    final entry = item.toEntry(time: today, meal: Meal.lunch, portions: 1.5);
    expect(entry.kcal, item.kcal * 1.5);
    expect(entry.protein, item.protein * 1.5);
    expect(item.lenten, isTrue);
  });

  test('BMI and its bands, as the WHO draws them', () {
    expect(Bmi.of(80, 178), closeTo(25.2, 0.05));
    expect(Bmi.category(18.4), BmiCategory.underweight);
    expect(Bmi.category(18.5), BmiCategory.healthy);
    expect(Bmi.category(24.99), BmiCategory.healthy);
    expect(Bmi.category(25), BmiCategory.overweight);
    expect(Bmi.category(30), BmiCategory.obese);
    // 18.5 × 1.78² = 58.6, 25 × 1.78² = 79.2.
    expect(Bmi.healthyRange(178), (59, 79));
  });
}
