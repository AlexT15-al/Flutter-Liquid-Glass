import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'csv.dart';

/// Everything Halo stores, as CSV files a spreadsheet opens, and back.
///
/// One file per kind of record, times in ISO 8601 local time. Importing adds
/// what is not there yet and leaves what is, so the same files can be
/// imported twice, or into a phone that already has some of the data, without
/// doubling anything. Settings (profile, goals, schedules) are replaced.
class DataTransfer {
  DataTransfer(this._db);

  final AppDatabase _db;

  static String _time(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String();

  static int? _ms(String? text) {
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.millisecondsSinceEpoch;
  }

  static double? _num(String? text) =>
      text == null || text.isEmpty ? null : double.tryParse(text);

  /// File name to contents.
  Future<Map<String, String>> export() async {
    final steps = await _db.select(_db.stepIntervals).get();
    final workouts = await _db.select(_db.workouts).get();
    final points = await _db.select(_db.workoutPoints).get();
    final sleep = await (_db.select(
      _db.sleepSessions,
    )..where((t) => t.endMs.isNotNull())).get();
    final food = await _db.select(_db.foodEntries).get();
    final water = await _db.select(_db.waterEntries).get();
    final weight = await _db.select(_db.weightEntries).get();
    final sets = await _db.select(_db.exerciseSets).get();
    final settings = await _db.select(_db.keyValues).get();
    final mindful = await _db.select(_db.mindfulSessions).get();
    final moods = await _db.select(_db.moodEntries).get();

    return {
      'steps.csv': Csv.encode(
        ['start', 'end', 'steps'],
        [
          for (final r in steps) [_time(r.startMs), _time(r.endMs), r.steps],
        ],
      ),
      'workouts.csv': Csv.encode(
        [
          'id',
          'type',
          'start',
          'end',
          'active_seconds',
          'distance_km',
          'active_kcal',
          'steps',
          'effort',
          'elevation_gain_m',
        ],
        [
          for (final r in workouts)
            [
              r.id,
              r.type,
              _time(r.startMs),
              _time(r.endMs),
              r.activeMs / 1000,
              r.distanceKm,
              r.activeKcal,
              r.steps,
              r.effort,
              r.elevationGainM,
            ],
        ],
      ),
      'workout_routes.csv': Csv.encode(
        [
          'workout_id',
          'latitude',
          'longitude',
          'altitude',
          'elapsed_ms',
          'segment',
        ],
        [
          for (final r in points)
            [
              r.workoutId,
              r.latitude,
              r.longitude,
              r.altitude,
              r.elapsedMs,
              r.segment,
            ],
        ],
      ),
      'sleep.csv': Csv.encode(
        ['in_bed', 'out_of_bed', 'source', 'stages'],
        [
          for (final r in sleep)
            [_time(r.startMs), _time(r.endMs!), r.source, r.hypnogram],
        ],
      ),
      'food.csv': Csv.encode(
        [
          'time',
          'meal',
          'name',
          'kcal',
          'protein_g',
          'carbs_g',
          'fat_g',
          'portions',
        ],
        [
          for (final r in food)
            [
              _time(r.timeMs),
              r.meal,
              r.name,
              r.kcal,
              r.protein,
              r.carbs,
              r.fat,
              r.portions,
            ],
        ],
      ),
      'water.csv': Csv.encode(
        ['time', 'ml'],
        [
          for (final r in water) [_time(r.timeMs), r.ml],
        ],
      ),
      'weight.csv': Csv.encode(
        ['time', 'kg'],
        [
          for (final r in weight) [_time(r.timeMs), r.kg],
        ],
      ),
      'training_sets.csv': Csv.encode(
        ['session_start', 'exercise', 'reps', 'kg'],
        [
          for (final r in sets) [_time(r.timeMs), r.exerciseId, r.reps, r.kg],
        ],
      ),
      'mindful_minutes.csv': Csv.encode(
        ['start', 'seconds', 'kind'],
        [
          for (final r in mindful) [_time(r.startMs), r.seconds, r.kind],
        ],
      ),
      'moods.csv': Csv.encode(
        ['time', 'valence_0_to_6', 'feelings', 'contexts'],
        [
          for (final r in moods)
            [_time(r.timeMs), r.valence, r.feelings, r.contexts],
        ],
      ),
      'settings.csv': Csv.encode(
        ['key', 'value'],
        [
          for (final r in settings) [r.key, r.value],
        ],
      ),
    };
  }

  /// Reads files exported by [export], by name. Returns how many records
  /// were added. Files it does not know are ignored.
  Future<int> import(Map<String, String> files) async {
    String? file(String name) {
      for (final e in files.entries) {
        if (e.key.toLowerCase().endsWith(name)) return e.value;
      }
      return null;
    }

    var added = 0;
    await _db.transaction(() async {
      // Steps.
      if (file('steps.csv') case final text?) {
        final have = {
          for (final r in await _db.select(_db.stepIntervals).get())
            '${r.startMs}:${r.endMs}',
        };
        for (final row in Csv.decode(text)) {
          final start = _ms(row['start']);
          final end = _ms(row['end']);
          final steps = int.tryParse(row['steps'] ?? '');
          if (start == null || end == null || steps == null) continue;
          if (!have.add('$start:$end')) continue;
          await _db
              .into(_db.stepIntervals)
              .insert(
                StepIntervalsCompanion.insert(
                  startMs: start,
                  endMs: end,
                  steps: steps,
                ),
              );
          added++;
        }
      }

      // Workouts, then their routes under the ids they get here.
      final newIds = <String, int>{};
      if (file('workouts.csv') case final text?) {
        final have = {
          for (final r in await _db.select(_db.workouts).get())
            '${r.type}:${r.startMs}': r.id,
        };
        for (final row in Csv.decode(text)) {
          final type = row['type'] ?? '';
          final start = _ms(row['start']);
          final end = _ms(row['end']);
          if (type.isEmpty || start == null || end == null) continue;
          final existing = have['$type:$start'];
          if (existing != null) {
            newIds[row['id'] ?? ''] = existing;
            continue;
          }
          final id = await _db
              .into(_db.workouts)
              .insert(
                WorkoutsCompanion.insert(
                  type: type,
                  startMs: start,
                  endMs: end,
                  activeMs: ((_num(row['active_seconds']) ?? 0) * 1000).round(),
                  distanceKm: _num(row['distance_km']) ?? 0,
                  activeKcal: _num(row['active_kcal']) ?? 0,
                  steps: int.tryParse(row['steps'] ?? '') ?? 0,
                  effort: Value(int.tryParse(row['effort'] ?? '')),
                  elevationGainM: Value(_num(row['elevation_gain_m']) ?? 0),
                ),
              );
          newIds[row['id'] ?? ''] = id;
          have['$type:$start'] = id;
          added++;
        }
      }
      if (file('workout_routes.csv') case final text?) {
        final routed = {
          for (final r in await _db.select(_db.workoutPoints).get())
            r.workoutId,
        };
        final rows = <WorkoutPointsCompanion>[];
        for (final row in Csv.decode(text)) {
          final id = newIds[row['workout_id'] ?? ''];
          final lat = _num(row['latitude']);
          final lon = _num(row['longitude']);
          // A workout that already had its route keeps it.
          if (id == null || lat == null || lon == null || routed.contains(id)) {
            continue;
          }
          rows.add(
            WorkoutPointsCompanion.insert(
              workoutId: id,
              latitude: lat,
              longitude: lon,
              altitude: Value(_num(row['altitude'])),
              elapsedMs: int.tryParse(row['elapsed_ms'] ?? '') ?? 0,
              segment: int.tryParse(row['segment'] ?? '') ?? 0,
            ),
          );
        }
        await _db.batch((b) => b.insertAll(_db.workoutPoints, rows));
      }

      // Sleep.
      if (file('sleep.csv') case final text?) {
        final have = {
          for (final r in await _db.select(_db.sleepSessions).get()) r.startMs,
        };
        for (final row in Csv.decode(text)) {
          final start = _ms(row['in_bed']);
          final end = _ms(row['out_of_bed']);
          if (start == null || end == null || !have.add(start)) continue;
          await _db
              .into(_db.sleepSessions)
              .insert(
                SleepSessionsCompanion.insert(
                  startMs: start,
                  endMs: Value(end),
                  source: (row['source'] ?? '').isEmpty
                      ? 'manual'
                      : row['source']!,
                  hypnogram: Value(row['stages'] ?? ''),
                ),
              );
          added++;
        }
      }

      // Food.
      if (file('food.csv') case final text?) {
        final have = {
          for (final r in await _db.select(_db.foodEntries).get())
            '${r.timeMs}:${r.name}',
        };
        for (final row in Csv.decode(text)) {
          final time = _ms(row['time']);
          final name = row['name'] ?? '';
          if (time == null || name.isEmpty || !have.add('$time:$name')) {
            continue;
          }
          await _db
              .into(_db.foodEntries)
              .insert(
                FoodEntriesCompanion.insert(
                  timeMs: time,
                  meal: (row['meal'] ?? '').isEmpty ? 'snack' : row['meal']!,
                  name: name,
                  kcal: Value(_num(row['kcal'])),
                  protein: Value(_num(row['protein_g'])),
                  carbs: Value(_num(row['carbs_g'])),
                  fat: Value(_num(row['fat_g'])),
                  portions: Value(_num(row['portions']) ?? 1),
                ),
              );
          added++;
        }
      }

      // Water and weight.
      if (file('water.csv') case final text?) {
        final have = {
          for (final r in await _db.select(_db.waterEntries).get()) r.timeMs,
        };
        for (final row in Csv.decode(text)) {
          final time = _ms(row['time']);
          final ml = int.tryParse(row['ml'] ?? '');
          if (time == null || ml == null || !have.add(time)) continue;
          await _db.insertWater(DateTime.fromMillisecondsSinceEpoch(time), ml);
          added++;
        }
      }
      if (file('weight.csv') case final text?) {
        final have = {
          for (final r in await _db.select(_db.weightEntries).get()) r.timeMs,
        };
        for (final row in Csv.decode(text)) {
          final time = _ms(row['time']);
          final kg = _num(row['kg']);
          if (time == null || kg == null || !have.add(time)) continue;
          await _db.insertWeight(DateTime.fromMillisecondsSinceEpoch(time), kg);
          added++;
        }
      }

      // Training sets: a session already here is not added again.
      if (file('training_sets.csv') case final text?) {
        final have = {
          for (final r in await _db.select(_db.exerciseSets).get())
            '${r.timeMs}:${r.exerciseId}',
        };
        final rows = <ExerciseSetsCompanion>[];
        for (final row in Csv.decode(text)) {
          final time = _ms(row['session_start']);
          final exercise = row['exercise'] ?? '';
          final reps = int.tryParse(row['reps'] ?? '');
          if (time == null || exercise.isEmpty || reps == null) continue;
          if (have.contains('$time:$exercise')) continue;
          rows.add(
            ExerciseSetsCompanion.insert(
              timeMs: time,
              exerciseId: exercise,
              reps: reps,
              kg: Value(_num(row['kg'])),
            ),
          );
        }
        await _db.insertSets(rows);
        added += rows.length;
      }

      // Mindful minutes and moods.
      if (file('mindful_minutes.csv') case final text?) {
        final have = {
          for (final r in await _db.select(_db.mindfulSessions).get())
            r.startMs,
        };
        for (final row in Csv.decode(text)) {
          final start = _ms(row['start']);
          final seconds = int.tryParse(row['seconds'] ?? '');
          if (start == null || seconds == null || !have.add(start)) continue;
          await _db
              .into(_db.mindfulSessions)
              .insert(
                MindfulSessionsCompanion.insert(
                  startMs: start,
                  seconds: seconds,
                  kind: (row['kind'] ?? '').isEmpty ? 'meditate' : row['kind']!,
                ),
              );
          added++;
        }
      }
      if (file('moods.csv') case final text?) {
        final have = {
          for (final r in await _db.select(_db.moodEntries).get()) r.timeMs,
        };
        for (final row in Csv.decode(text)) {
          final time = _ms(row['time']);
          final valence = int.tryParse(row['valence_0_to_6'] ?? '');
          if (time == null || valence == null || !have.add(time)) continue;
          await _db
              .into(_db.moodEntries)
              .insert(
                MoodEntriesCompanion.insert(
                  timeMs: time,
                  valence: valence.clamp(0, 6),
                  feelings: Value(row['feelings'] ?? ''),
                  contexts: Value(row['contexts'] ?? ''),
                ),
              );
          added++;
        }
      }

      // Settings: the file's values win.
      if (file('settings.csv') case final text?) {
        for (final row in Csv.decode(text)) {
          final key = row['key'] ?? '';
          if (key.isEmpty) continue;
          // The step counter's position belongs to this phone's sensor.
          if (key == 'step_counter') continue;
          await _db.writeValue(key, row['value'] ?? '');
        }
      }
    });
    return added;
  }
}
