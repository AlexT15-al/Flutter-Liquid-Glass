import 'package:drift/drift.dart' show Value;

import '../../domain/nutrition.dart';
import '../database/app_database.dart';

/// What was eaten and drunk, and the weigh-ins.
class NutritionRepository {
  NutritionRepository(this._db);

  final AppDatabase _db;

  Future<int> addFood(FoodEntry entry) => _db.insertFood(_companion(entry));

  Future<void> updateFood(FoodEntry entry) =>
      _db.updateFood(entry.id!, _companion(entry));

  Future<void> deleteFood(int id) => _db.deleteFood(id);

  /// Everything eaten on [day], in the order it was logged.
  Stream<List<FoodEntry>> watchFoodOn(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    return watchFoodBetween(
      from,
      DateTime(from.year, from.month, from.day + 1),
    );
  }

  Stream<List<FoodEntry>> watchFoodBetween(DateTime from, DateTime to) =>
      _db.watchFoodBetween(from, to).map((rows) => rows.map(_entry).toList());

  /// Foods logged lately, each name once, newest first.
  Future<List<FoodEntry>> recent({int limit = 8}) async {
    final seen = <String>{};
    final out = <FoodEntry>[];
    for (final row in await _db.recentFoods(60)) {
      if (seen.add(row.name.toLowerCase())) out.add(_entry(row));
      if (out.length == limit) break;
    }
    return out;
  }

  Future<void> addWater(DateTime time, int ml) => _db.insertWater(time, ml);

  Future<void> deleteWater(int id) => _db.deleteWater(id);

  /// Each glass logged on [day], as `(id, ml)`, in order.
  Stream<List<(int, int)>> watchWaterOn(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    return _db
        .watchWaterBetween(from, DateTime(from.year, from.month, from.day + 1))
        .map((rows) => [for (final r in rows) (r.id, r.ml)]);
  }

  /// Every glass between [from] and [to], as `(id, time, ml)`.
  Stream<List<(int, DateTime, int)>> watchWaterBetween(
    DateTime from,
    DateTime to,
  ) => _db
      .watchWaterBetween(from, to)
      .map(
        (rows) => [
          for (final r in rows)
            (r.id, DateTime.fromMillisecondsSinceEpoch(r.timeMs), r.ml),
        ],
      );

  Future<void> addWeight(DateTime time, double kg) =>
      _db.insertWeight(time, kg);

  /// Weigh-ins, newest first, as `(time, kg)`.
  Stream<List<(DateTime, double)>> watchWeights({int limit = 60}) => _db
      .watchWeights(limit)
      .map(
        (rows) => [
          for (final r in rows)
            (DateTime.fromMillisecondsSinceEpoch(r.timeMs), r.kg),
        ],
      );

  static FoodEntriesCompanion _companion(FoodEntry e) =>
      FoodEntriesCompanion.insert(
        timeMs: e.time.millisecondsSinceEpoch,
        meal: e.meal.name,
        name: e.name,
        kcal: Value(e.kcal),
        protein: Value(e.protein),
        carbs: Value(e.carbs),
        fat: Value(e.fat),
        portions: Value(e.portions),
      );

  static FoodEntry _entry(FoodRow r) => FoodEntry(
    id: r.id,
    time: DateTime.fromMillisecondsSinceEpoch(r.timeMs),
    meal: Meal.byName(r.meal),
    name: r.name,
    kcal: r.kcal,
    protein: r.protein,
    carbs: r.carbs,
    fat: r.fat,
    portions: r.portions,
  );
}
