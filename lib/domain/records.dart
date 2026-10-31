import 'training.dart';
import 'workout.dart';

/// One best: what it is, the value, and the workout or day it was set.
class PersonalRecord {
  const PersonalRecord({
    required this.title,
    required this.value,
    required this.date,
    this.workout,
  });

  final String title;

  /// Already formatted: `12.4 km`, `5'02" /km`, `92.5 kg`.
  final String value;
  final DateTime date;

  /// The workout it belongs to, for opening it.
  final WorkoutRecord? workout;
}

/// Bests worked out from everything recorded.
abstract final class Records {
  /// For each kind of workout done: longest, longest time, most energy and,
  /// where there is distance, the fastest average pace over at least a
  /// kilometre.
  static Map<WorkoutType, List<PersonalRecord>> workouts(
    List<WorkoutRecord> all,
    String Function(Duration) pace,
    String Function(Duration) clock,
  ) {
    final byType = <WorkoutType, List<WorkoutRecord>>{};
    for (final w in all) {
      (byType[w.type] ??= []).add(w);
    }
    WorkoutRecord best(
      List<WorkoutRecord> list,
      num Function(WorkoutRecord) of,
    ) => list.reduce((a, b) => of(b) > of(a) ? b : a);

    return {
      for (final MapEntry(key: type, value: list) in byType.entries)
        type: [
          if (type.hasDistance && list.any((w) => w.distanceKm > 0)) ...[
            () {
              final w = best(list, (w) => w.distanceKm);
              return PersonalRecord(
                title: 'Longest Distance',
                value: '${w.distanceKm.toStringAsFixed(2)} km',
                date: w.start,
                workout: w,
              );
            }(),
            if (list.any((w) => w.distanceKm >= 1))
              () {
                final w = best([
                  for (final w in list)
                    if (w.distanceKm >= 1) w,
                ], (w) => w.distanceKm / w.activeDuration.inSeconds);
                return PersonalRecord(
                  title: type == WorkoutType.outdoorCycle
                      ? 'Fastest Average Speed'
                      : 'Fastest Average Pace',
                  value: type == WorkoutType.outdoorCycle
                      ? '${(w.distanceKm / w.activeDuration.inSeconds * 3600).toStringAsFixed(1)} km/h'
                      : '${pace(Duration(seconds: (w.activeDuration.inSeconds / w.distanceKm).round()))} /km',
                  date: w.start,
                  workout: w,
                );
              }(),
          ],
          () {
            final w = best(list, (w) => w.activeDuration.inSeconds);
            return PersonalRecord(
              title: 'Longest Workout',
              value: clock(w.activeDuration),
              date: w.start,
              workout: w,
            );
          }(),
          () {
            final w = best(list, (w) => w.activeKcal);
            return PersonalRecord(
              title: 'Most Energy',
              value: '${w.activeKcal.round()} kcal',
              date: w.start,
              workout: w,
            );
          }(),
        ],
    };
  }

  /// One rep max estimated by Epley's formula, the one most apps use:
  /// `kg × (1 + reps / 30)`; a single is the lift itself.
  static double oneRepMax(double kg, int reps) =>
      reps <= 1 ? kg : kg * (1 + reps / 30);

  /// For each loaded exercise trained: the heaviest set and the best
  /// estimated one rep max. Bodyweight exercises: the most reps in a set.
  static Map<Exercise, List<PersonalRecord>> strength(List<SetLog> sets) {
    final byExercise = <String, List<SetLog>>{};
    for (final s in sets) {
      (byExercise[s.exerciseId] ??= []).add(s);
    }
    String kg(double v) =>
        v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
    final out = <Exercise, List<PersonalRecord>>{};
    for (final MapEntry(key: id, value: list) in byExercise.entries) {
      final exercise = ExerciseCatalog.tryId(id);
      if (exercise == null) continue;
      final loaded = list.where((s) => (s.kg ?? 0) > 0).toList();
      if (loaded.isNotEmpty) {
        final heaviest = loaded.reduce(
          (a, b) => b.kg! > a.kg! || (b.kg == a.kg && b.reps > a.reps) ? b : a,
        );
        final strongest = loaded.reduce(
          (a, b) => oneRepMax(b.kg!, b.reps) > oneRepMax(a.kg!, a.reps) ? b : a,
        );
        out[exercise] = [
          PersonalRecord(
            title: 'Heaviest Set',
            value: '${kg(heaviest.kg!)} kg × ${heaviest.reps}',
            date: heaviest.time,
          ),
          PersonalRecord(
            title: 'Estimated 1RM',
            value: '${kg(oneRepMax(strongest.kg!, strongest.reps))} kg',
            date: strongest.time,
          ),
        ];
      } else {
        final most = list.reduce((a, b) => b.reps > a.reps ? b : a);
        out[exercise] = [
          PersonalRecord(
            title: exercise.measure == Measure.seconds
                ? 'Longest Hold'
                : 'Most Reps',
            value: exercise.measure == Measure.seconds
                ? '${most.reps} s'
                : '${most.reps} reps',
            date: most.time,
          ),
        ];
      }
    }
    return out;
  }
}
