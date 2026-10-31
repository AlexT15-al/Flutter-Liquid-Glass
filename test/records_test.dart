import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/records.dart';
import 'package:halo/domain/training.dart';
import 'package:halo/domain/workout.dart';
import 'package:halo/shared/format.dart';

WorkoutRecord run(int day, double km, int minutes, double kcal) {
  final start = DateTime(2026, 10, day, 18);
  return WorkoutRecord(
    type: WorkoutType.outdoorRun,
    start: start,
    end: start.add(Duration(minutes: minutes)),
    activeDuration: Duration(minutes: minutes),
    distanceKm: km,
    activeKcal: kcal,
    steps: 0,
  );
}

void main() {
  test('workout bests: longest, fastest, longest time, most energy', () {
    final records = Records.workouts(
      [run(1, 5, 30, 350), run(3, 10, 65, 700), run(5, 3, 15, 220)],
      Format.pace,
      Format.clock,
    )[WorkoutType.outdoorRun]!;
    final byTitle = {for (final r in records) r.title: r};
    expect(byTitle['Longest Distance']!.value, '10.00 km');
    // 3 km in 15 min is 5'00" a km, faster than 6'00" and 6'30".
    expect(byTitle['Fastest Average Pace']!.value, '5\'00" /km');
    expect(byTitle['Longest Workout']!.value, '1:05:00');
    expect(byTitle['Most Energy']!.date.day, 3);
  });

  test('strength bests: heaviest set and estimated one rep max', () {
    final t = DateTime(2026, 10, 1);
    final records = Records.strength([
      SetLog(time: t, exerciseId: 'back_squat', reps: 10, kg: 80),
      SetLog(time: t, exerciseId: 'back_squat', reps: 3, kg: 95),
      SetLog(time: t, exerciseId: 'pushup', reps: 22),
    ]);
    final squat = records[ExerciseCatalog.byId('back_squat')]!;
    expect(squat[0].value, '95 kg × 3');
    // 80 × (1 + 10/30) = 106.7 beats 95 × 1.1 = 104.5.
    expect(squat[1].value, '106.7 kg');
    expect(records[ExerciseCatalog.byId('pushup')]!.single.value, '22 reps');
  });
}
