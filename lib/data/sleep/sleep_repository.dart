import 'package:drift/drift.dart' show Value;

import '../../domain/sleep.dart';
import '../database/app_database.dart';

/// Nights, stored: the one being tracked and every finished one.
class SleepRepository {
  SleepRepository(this._db);

  final AppDatabase _db;

  /// Opens a tracked night. Its minutes are added as they come in.
  Future<int> begin(DateTime inBed) => _db.insertSleepSession(
    SleepSessionsCompanion.insert(
      startMs: inBed.millisecondsSinceEpoch,
      source: SleepSource.tracked.name,
    ),
  );

  Future<void> putMinute(int sessionId, int minute, int count) =>
      _db.putSleepMinute(sessionId, minute, count);

  /// The night being tracked, as its id and start, if one is open.
  Future<(int, DateTime)?> open() async {
    final row = await _db.openSleepSession();
    if (row == null) return null;
    return (row.id, DateTime.fromMillisecondsSinceEpoch(row.startMs));
  }

  /// The last minute recorded for a session, or -1 if none was.
  Future<int> lastMinute(int sessionId) async {
    final rows = await _db.sleepMinutesOf(sessionId);
    return rows.isEmpty ? -1 : rows.last.minute;
  }

  /// Closes a tracked night at [outOfBed] and works out its stages from the
  /// minutes recorded. A minute with nothing recorded (the phone missed it)
  /// counts as still.
  Future<SleepNight> finish(int id, DateTime outOfBed) async {
    final session = await _db.openSleepSession();
    final start = session != null && session.id == id
        ? DateTime.fromMillisecondsSinceEpoch(session.startMs)
        : outOfBed;
    final length = outOfBed.difference(start).inMinutes;
    final counts = List.filled(length < 0 ? 0 : length, 0);
    for (final row in await _db.sleepMinutesOf(id)) {
      if (row.minute >= 0 && row.minute < counts.length) {
        counts[row.minute] = row.count;
      }
    }
    final night = SleepNight(
      id: id,
      source: SleepSource.tracked,
      inBed: start,
      outOfBed: outOfBed,
      hypnogram: SleepAnalysis.hypnogram(counts),
    );
    await _db.updateSleepSession(
      id,
      SleepSessionsCompanion(
        endMs: Value(outOfBed.millisecondsSinceEpoch),
        hypnogram: Value(night.hypnogramCode),
      ),
    );
    return night;
  }

  /// Whether any night already covers part of `[from, to)`.
  Future<bool> overlaps(DateTime from, DateTime to) async =>
      (await _db.sleepSessionsOverlapping(from, to)).isNotEmpty;

  /// A night worked out from the phone's use, as the user recorded it.
  Future<int> addNight(SleepNight night) => _db.insertSleepSession(
    SleepSessionsCompanion.insert(
      startMs: night.inBed.millisecondsSinceEpoch,
      endMs: Value(night.outOfBed.millisecondsSinceEpoch),
      source: night.source.name,
      hypnogram: Value(night.hypnogramCode),
    ),
  );

  /// A night entered by hand: times only.
  Future<int> addManual(DateTime inBed, DateTime outOfBed) =>
      _db.insertSleepSession(
        SleepSessionsCompanion.insert(
          startMs: inBed.millisecondsSinceEpoch,
          endMs: Value(outOfBed.millisecondsSinceEpoch),
          source: SleepSource.manual.name,
        ),
      );

  /// For tests and the screenshots: a finished night as it would be stored.
  Future<int> addTracked(DateTime inBed, List<int> counts) async {
    final id = await begin(inBed);
    for (var i = 0; i < counts.length; i++) {
      await putMinute(id, i, counts[i]);
    }
    await finish(id, inBed.add(Duration(minutes: counts.length)));
    return id;
  }

  Future<void> delete(int id) => _db.deleteSleepSession(id);

  /// The latest [limit] finished nights, newest first.
  Stream<List<SleepNight>> watchNights(int limit) => _db
      .watchSleepSessions(limit)
      .map(
        (rows) => [
          for (final row in rows)
            SleepNight(
              id: row.id,
              source: SleepSource.byName(row.source),
              inBed: DateTime.fromMillisecondsSinceEpoch(row.startMs),
              outOfBed: DateTime.fromMillisecondsSinceEpoch(row.endMs!),
              hypnogram: SleepNight.parseHypnogram(row.hypnogram),
            ),
        ],
      );
}
