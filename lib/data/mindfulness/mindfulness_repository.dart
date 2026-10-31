import 'package:drift/drift.dart';

import '../../domain/mindfulness.dart';
import '../database/app_database.dart';

/// Mindful minutes and moods.
class MindfulnessRepository {
  MindfulnessRepository(this._db);

  final AppDatabase _db;

  Future<void> addSession(MindfulSession session) => _db
      .into(_db.mindfulSessions)
      .insert(
        MindfulSessionsCompanion.insert(
          startMs: session.start.millisecondsSinceEpoch,
          seconds: session.length.inSeconds,
          kind: session.kind.name,
        ),
      );

  /// Sessions since [from], newest first.
  Stream<List<MindfulSession>> watchSessionsSince(DateTime from) =>
      (_db.select(_db.mindfulSessions)
            ..where(
              (t) =>
                  t.startMs.isBiggerOrEqualValue(from.millisecondsSinceEpoch),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startMs)]))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                MindfulSession(
                  id: r.id,
                  start: DateTime.fromMillisecondsSinceEpoch(r.startMs),
                  length: Duration(seconds: r.seconds),
                  kind: MindfulKind.byName(r.kind),
                ),
            ],
          );

  Future<void> addMood(MoodEntry mood) => _db
      .into(_db.moodEntries)
      .insert(
        MoodEntriesCompanion.insert(
          timeMs: mood.time.millisecondsSinceEpoch,
          valence: mood.valence,
          feelings: Value(mood.feelings.join(',')),
          contexts: Value(mood.contexts.join(',')),
        ),
      );

  Future<void> deleteMood(int id) =>
      (_db.delete(_db.moodEntries)..where((t) => t.id.equals(id))).go();

  /// Moods since [from], newest first.
  Stream<List<MoodEntry>> watchMoodsSince(DateTime from) =>
      (_db.select(_db.moodEntries)
            ..where(
              (t) => t.timeMs.isBiggerOrEqualValue(from.millisecondsSinceEpoch),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.timeMs)]))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                MoodEntry(
                  id: r.id,
                  time: DateTime.fromMillisecondsSinceEpoch(r.timeMs),
                  valence: r.valence,
                  feelings: {
                    for (final f in r.feelings.split(','))
                      if (f.isNotEmpty) f,
                  },
                  contexts: {
                    for (final c in r.contexts.split(','))
                      if (c.isNotEmpty) c,
                  },
                ),
            ],
          );
}
