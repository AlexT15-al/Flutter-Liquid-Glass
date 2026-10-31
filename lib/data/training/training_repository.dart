import 'package:drift/drift.dart' show Value;

import '../../domain/training.dart';
import '../database/app_database.dart';

/// The sets done in planned sessions: what progression is worked out from.
class TrainingRepository {
  TrainingRepository(this._db);

  final AppDatabase _db;

  Future<void> saveSession(List<SetLog> sets) => _db.insertSets([
    for (final s in sets)
      ExerciseSetsCompanion.insert(
        timeMs: s.time.millisecondsSinceEpoch,
        exerciseId: s.exerciseId,
        reps: s.reps,
        kg: Value(s.kg),
      ),
  ]);

  /// Every set ever logged, for records.
  Stream<List<SetLog>> watchAll() => _db
      .watchSetsSince(DateTime.fromMillisecondsSinceEpoch(0))
      .map(
        (rows) => [
          for (final r in rows)
            SetLog(
              time: DateTime.fromMillisecondsSinceEpoch(r.timeMs),
              exerciseId: r.exerciseId,
              reps: r.reps,
              kg: r.kg,
            ),
        ],
      );

  /// The last twelve weeks of sets: more than progression ever looks back.
  Stream<List<SetLog>> watchHistory() => _db
      .watchSetsSince(DateTime.now().subtract(const Duration(days: 84)))
      .map(
        (rows) => [
          for (final r in rows)
            SetLog(
              time: DateTime.fromMillisecondsSinceEpoch(r.timeMs),
              exerciseId: r.exerciseId,
              reps: r.reps,
              kg: r.kg,
            ),
        ],
      );
}
