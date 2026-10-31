import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/awards/award_stats_loader.dart';
import 'package:halo/data/database/app_database.dart';
import 'package:halo/data/nutrition/nutrition_repository.dart';
import 'package:halo/data/sleep/sleep_repository.dart';
import 'package:halo/domain/awards.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('stats are counted from what is stored', () async {
    final db = AppDatabase.forExecutor(
      DatabaseConnection(NativeDatabase.memory()),
    );
    final day = DateTime(2026, 10, 20);
    await db.insertStepInterval(
      start: day.add(const Duration(hours: 9)),
      end: day.add(const Duration(hours: 10)),
      steps: 6000,
    );
    await db.insertStepInterval(
      start: day.add(const Duration(hours: 17)),
      end: day.add(const Duration(hours: 18)),
      steps: 5000,
    );
    final sleep = SleepRepository(db);
    // Seven nights of eight hours in a row, then a gap, then one more.
    for (var i = 0; i < 7; i++) {
      final end = day.add(Duration(days: i, hours: 7));
      await sleep.addManual(end.subtract(const Duration(hours: 8)), end);
    }
    final lone = day.add(const Duration(days: 10, hours: 7));
    await sleep.addManual(lone.subtract(const Duration(hours: 8)), lone);
    final nutrition = NutritionRepository(db);
    for (var i = 0; i < 8; i++) {
      await nutrition.addWater(day.add(Duration(hours: 8 + i)), 250);
    }

    final stats = await AwardStatsLoader.load(db);
    expect(stats.bestStepsDay, 11000);
    expect(stats.nightsTracked, 8);
    expect(stats.longestRestedStreak, 7);
    expect(stats.hydratedDays, 1);

    final awards = {for (final a in Award.all(stats)) a.title: a};
    expect(awards['10,000 Steps']!.earned, isTrue);
    expect(awards['20,000 Steps']!.progress, closeTo(0.55, 0.001));
    expect(awards['Well Rested']!.earned, isTrue);
    expect(awards['First Workout']!.earned, isFalse);
  });
}
