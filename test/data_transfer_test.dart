import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/database/app_database.dart';
import 'package:halo/data/nutrition/nutrition_repository.dart';
import 'package:halo/data/sleep/sleep_repository.dart';
import 'package:halo/data/training/training_repository.dart';
import 'package:halo/data/transfer/csv.dart';
import 'package:halo/data/transfer/data_transfer.dart';
import 'package:halo/data/workouts/workout_repository.dart';
import 'package:halo/domain/nutrition.dart';
import 'package:halo/domain/route.dart';
import 'package:halo/domain/training.dart';
import 'package:halo/domain/workout.dart';

AppDatabase _db() =>
    AppDatabase.forExecutor(DatabaseConnection(NativeDatabase.memory()));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final t = DateTime(2026, 10, 30, 18);

  test('csv quotes what needs quoting and reads it back', () {
    final text = Csv.encode(
      ['name', 'note'],
      [
        ['Souvlaki, chicken', 'said "great"'],
        ['Line\nbreak', null],
      ],
    );
    final rows = Csv.decode(text);
    expect(rows[0]['name'], 'Souvlaki, chicken');
    expect(rows[0]['note'], 'said "great"');
    expect(rows[1]['name'], 'Line\nbreak');
    expect(rows[1]['note'], '');
  });

  test('everything survives an export and an import, and only once', () async {
    final a = _db();
    await a.insertStepInterval(
      start: t,
      end: t.add(const Duration(minutes: 5)),
      steps: 480,
    );
    await WorkoutRepository(a).save(
      WorkoutRecord(
        type: WorkoutType.outdoorRun,
        start: t,
        end: t.add(const Duration(minutes: 30)),
        activeDuration: const Duration(minutes: 29),
        distanceKm: 5.1,
        activeKcal: 380,
        steps: 5000,
        effort: 6,
        route: [
          for (var i = 0; i < 3; i++)
            RoutePoint(
              latitude: 37.97 + i / 1000,
              longitude: 23.72,
              time: t.add(Duration(minutes: i)),
              elapsed: Duration(minutes: i),
            ),
        ],
      ),
    );
    await SleepRepository(
      a,
    ).addManual(DateTime(2026, 10, 30, 23, 30), DateTime(2026, 10, 31, 7));
    final nutrition = NutritionRepository(a);
    await nutrition.addFood(
      FoodEntry(
        time: t,
        meal: Meal.dinner,
        name: 'Fasolada, "home"',
        kcal: 380,
      ),
    );
    await nutrition.addWater(t, 250);
    await nutrition.addWeight(t, 81.4);
    await TrainingRepository(a).saveSession([
      SetLog(time: t, exerciseId: 'back_squat', reps: 10, kg: 60),
      SetLog(time: t, exerciseId: 'back_squat', reps: 9, kg: 60),
    ]);
    await a.writeValue('theme_mode', 'dark');

    final files = await DataTransfer(a).export();
    expect(files.keys, contains('workouts.csv'));

    final b = _db();
    final added = await DataTransfer(b).import(files);
    // 1 steps + 1 workout + 1 night + 1 food + 1 water + 1 weight + 2 sets.
    expect(added, 8);
    expect((await b.select(b.workoutPoints).get()).length, 3);
    expect(await b.readValue('theme_mode'), 'dark');
    final food = await b.select(b.foodEntries).get();
    expect(food.single.name, 'Fasolada, "home"');
    final workout = (await b.select(b.workouts).get()).single;
    expect(workout.activeMs, const Duration(minutes: 29).inMilliseconds);

    // Again: nothing doubles.
    expect(await DataTransfer(b).import(files), 0);
    expect((await b.select(b.workoutPoints).get()).length, 3);
  });
}
