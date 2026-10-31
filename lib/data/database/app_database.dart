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

@DriftDatabase(tables: [StepIntervals, KeyValues])
class AppDatabase extends _$AppDatabase {
  /// Opened lazily: the file is not touched until the first query, so
  /// constructing this costs nothing at launch.
  AppDatabase() : super(driftDatabase(name: 'halo'));

  /// For tests.
  AppDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 1;

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
          ..where((t) =>
              t.endMs.isBiggerThanValue(fromMs) &
              t.startMs.isSmallerThanValue(toMs))
          ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
        .get();
  }

  // ── Key-value ──────────────────────────────────────────────────────────────

  Future<String?> readValue(String key) async {
    final row = await (select(keyValues)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchValue(String key) {
    return (select(keyValues)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<void> writeValue(String key, String value) {
    return into(keyValues).insertOnConflictUpdate(
      KeyValuesCompanion.insert(key: key, value: value),
    );
  }
}
