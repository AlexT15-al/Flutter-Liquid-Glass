import 'package:drift/drift.dart' show Value;

import '../../domain/route.dart';
import '../../domain/workout.dart';
import '../database/app_database.dart';

/// Stores and reads finished workouts.
class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  /// Stores the workout and, for a GPS workout, its route with it.
  Future<int> save(WorkoutRecord record) => _db.insertWorkoutWithRoute(
    WorkoutsCompanion.insert(
      type: record.type.name,
      startMs: record.start.millisecondsSinceEpoch,
      endMs: record.end.millisecondsSinceEpoch,
      activeMs: record.activeDuration.inMilliseconds,
      distanceKm: record.distanceKm,
      activeKcal: record.activeKcal,
      steps: record.steps,
      effort: Value(record.effort),
      elevationGainM: Value(record.elevationGainM),
    ),
    (id) => [
      for (final p in record.route)
        WorkoutPointsCompanion.insert(
          workoutId: id,
          latitude: p.latitude,
          longitude: p.longitude,
          altitude: Value(p.altitude),
          elapsedMs: p.elapsed.inMilliseconds,
          segment: p.segment,
        ),
    ],
  );

  /// The workout with its route loaded.
  Future<WorkoutRecord> withRoute(WorkoutRecord record) async {
    final id = record.id;
    if (id == null || !record.type.gps) return record;
    final rows = await _db.routeOf(id);
    return record.withRoute([
      for (final row in rows)
        RoutePoint(
          latitude: row.latitude,
          longitude: row.longitude,
          altitude: row.altitude,
          time: record.start.add(Duration(milliseconds: row.elapsedMs)),
          elapsed: Duration(milliseconds: row.elapsedMs),
          segment: row.segment,
        ),
    ]);
  }

  Future<void> delete(int id) => _db.deleteWorkout(id);

  Stream<List<WorkoutRecord>> watchRecent(int limit) =>
      _db.watchRecentWorkouts(limit).map(_records);

  Stream<List<WorkoutRecord>> watchBetween(DateTime from, DateTime to) =>
      _db.watchWorkoutsBetween(from, to).map(_records);

  static List<WorkoutRecord> _records(List<Workout> rows) => [
    for (final row in rows)
      // A type from a newer build is skipped rather than failing the list.
      if (WorkoutType.byName(row.type) case final type?)
        WorkoutRecord(
          id: row.id,
          type: type,
          start: DateTime.fromMillisecondsSinceEpoch(row.startMs),
          end: DateTime.fromMillisecondsSinceEpoch(row.endMs),
          activeDuration: Duration(milliseconds: row.activeMs),
          distanceKm: row.distanceKm,
          activeKcal: row.activeKcal,
          steps: row.steps,
          effort: row.effort,
          elevationGainM: row.elevationGainM,
        ),
  ];
}
