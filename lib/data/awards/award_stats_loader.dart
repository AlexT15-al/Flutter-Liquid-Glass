import 'dart:math' as math;

import '../../domain/awards.dart';
import '../../domain/sleep.dart';
import '../database/app_database.dart';

/// Counts what the awards are earned by, from everything stored.
abstract final class AwardStatsLoader {
  static DateTime _day(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime(t.year, t.month, t.day);
  }

  static Future<AwardStats> load(AppDatabase db) async {
    final workouts = await db.select(db.workouts).get();

    final steps = <DateTime, int>{};
    for (final r in await db.select(db.stepIntervals).get()) {
      final day = _day(r.startMs);
      steps[day] = (steps[day] ?? 0) + r.steps;
    }

    final nights = [
      for (final r in await (db.select(
        db.sleepSessions,
      )..where((t) => t.endMs.isNotNull())).get())
        SleepNight(
          source: SleepSource.byName(r.source),
          inBed: DateTime.fromMillisecondsSinceEpoch(r.startMs),
          outOfBed: DateTime.fromMillisecondsSinceEpoch(r.endMs!),
          hypnogram: SleepNight.parseHypnogram(r.hypnogram),
        ),
    ];
    final rested = {
      for (final n in nights)
        if (n.asleep >= const Duration(hours: 7)) n.morning,
    }.toList()..sort();
    var streak = 0;
    var best = 0;
    DateTime? previous;
    for (final day in rested) {
      streak = previous != null && day.difference(previous).inDays == 1
          ? streak + 1
          : 1;
      best = math.max(best, streak);
      previous = day;
    }

    final water = <DateTime, int>{};
    for (final r in await db.select(db.waterEntries).get()) {
      final day = _day(r.timeMs);
      water[day] = (water[day] ?? 0) + r.ml;
    }
    final foodDays = {
      for (final r in await db.select(db.foodEntries).get()) _day(r.timeMs),
    };
    final sessions = {
      for (final r in await db.select(db.exerciseSets).get()) r.timeMs,
    };

    return AwardStats(
      workouts: workouts.length,
      longestDistanceKm: workouts.fold(
        0.0,
        (m, w) => math.max(m, w.distanceKm),
      ),
      totalDistanceKm: workouts.fold(0.0, (t, w) => t + w.distanceKm),
      bestStepsDay: steps.values.fold(0, math.max),
      nightsTracked: nights.length,
      longestRestedStreak: best,
      hydratedDays: water.values.where((ml) => ml >= 2000).length,
      foodDays: foodDays.length,
      trainingSessions: sessions.length,
    );
  }
}
