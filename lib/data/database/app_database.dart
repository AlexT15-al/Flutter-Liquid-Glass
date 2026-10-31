import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// A stretch of time and the steps counted in it.
///
/// The phone's step counter is a running total since boot, so what the app
/// can observe is "this many steps happened between these two moments".
/// Storing exactly that, rather than pretending to know the minute each step
/// fell in, keeps a long gap while the app was closed honest: its steps count
/// towards the day, but its cadence is the average over the gap, so it never
/// invents brisk-walking minutes nobody measured.
@TableIndex(name: 'step_intervals_end', columns: {#endMs})
class StepIntervals extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Epoch milliseconds, local wall-clock independent.
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();

  IntColumn get steps => integer()();
}

/// Small settings and state, as JSON strings by key: the profile, the goals,
/// the Today layout, the step counter's last reading.
///
/// One table rather than one per setting: each is a handful of fields read
/// once and written rarely, and none is ever queried by its contents.
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// A finished workout.
@TableIndex(name: 'workouts_start', columns: {#startMs})
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `WorkoutType.name`.
  TextColumn get type => text()();

  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();

  /// Moving time, start to end less the pauses.
  IntColumn get activeMs => integer()();

  RealColumn get distanceKm => real()();
  RealColumn get activeKcal => real()();
  IntColumn get steps => integer()();
  IntColumn get effort => integer().nullable()();

  /// Metres climbed, for a GPS workout. Added in schema 3.
  RealColumn get elevationGainM => real().withDefault(const Constant(0.0))();
}

/// The route of a GPS workout, one row per fix, in order.
@TableIndex(name: 'workout_points_workout', columns: {#workoutId})
class WorkoutPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real().nullable()();

  /// Moving time at the fix.
  IntColumn get elapsedMs => integer()();

  /// The stretch of moving it belongs to; a new one after every pause.
  IntColumn get segment => integer()();
}

@DriftDatabase(tables: [StepIntervals, KeyValues, Workouts, WorkoutPoints])
class AppDatabase extends _$AppDatabase {
  /// Opened lazily: the file is not touched until the first query, so
  /// constructing this costs nothing at launch.
  AppDatabase() : super(driftDatabase(name: 'halo'));

  /// For tests.
  AppDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Created at the current shape, elevation column included.
        await m.createTable(workouts);
        await m.createIndex(workoutsStart);
      } else if (from < 3) {
        await m.addColumn(workouts, workouts.elevationGainM);
      }
      if (from < 3) {
        await m.createTable(workoutPoints);
        await m.createIndex(workoutPointsWorkout);
      }
    },
    // Route points go with their workout.
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ── Steps ──────────────────────────────────────────────────────────────────

  Future<void> insertStepInterval({
    required DateTime start,
    required DateTime end,
    required int steps,
  }) {
    return into(stepIntervals).insert(
      StepIntervalsCompanion.insert(
        startMs: start.millisecondsSinceEpoch,
        endMs: end.millisecondsSinceEpoch,
        steps: steps,
      ),
    );
  }

  /// Every interval that overlaps `[from, to)`, oldest first.
  Future<List<StepInterval>> stepIntervalsBetween(DateTime from, DateTime to) {
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;
    return (select(stepIntervals)
          ..where(
            (t) =>
                t.endMs.isBiggerThanValue(fromMs) &
                t.startMs.isSmallerThanValue(toMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
        .get();
  }

  // ── Workouts ───────────────────────────────────────────────────────────────

  Future<int> insertWorkout(WorkoutsCompanion workout) =>
      into(workouts).insert(workout);

  /// Stores a workout and its route in one transaction: a workout never
  /// exists with half a route.
  Future<int> insertWorkoutWithRoute(
    WorkoutsCompanion workout,
    List<WorkoutPointsCompanion> Function(int id) points,
  ) {
    return transaction(() async {
      final id = await into(workouts).insert(workout);
      await batch((b) => b.insertAll(workoutPoints, points(id)));
      return id;
    });
  }

  Future<void> deleteWorkout(int id) =>
      (delete(workouts)..where((t) => t.id.equals(id))).go();

  Future<List<WorkoutPoint>> routeOf(int workoutId) =>
      (select(workoutPoints)
            ..where((t) => t.workoutId.equals(workoutId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// Workouts that started in `[from, to)`, newest first, as they change.
  Stream<List<Workout>> watchWorkoutsBetween(DateTime from, DateTime to) {
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;
    return (select(workouts)
          ..where(
            (t) =>
                t.startMs.isBiggerOrEqualValue(fromMs) &
                t.startMs.isSmallerThanValue(toMs),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startMs)]))
        .watch();
  }

  /// The latest [limit] workouts, newest first.
  Stream<List<Workout>> watchRecentWorkouts(int limit) =>
      (select(workouts)
            ..orderBy([(t) => OrderingTerm.desc(t.startMs)])
            ..limit(limit))
          .watch();

  // ── Key-value ──────────────────────────────────────────────────────────────

  Future<String?> readValue(String key) async {
    final row = await (select(
      keyValues,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchValue(String key) {
    return (select(keyValues)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<void> writeValue(String key, String value) {
    return into(
      keyValues,
    ).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value));
  }
}
