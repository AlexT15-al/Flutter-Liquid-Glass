import 'package:flutter/widgets.dart';

import '../data/activity/activity_store.dart';
import '../data/activity/step_tracker.dart';
import '../data/database/app_database.dart';
import '../data/nutrition/nutrition_repository.dart';
import '../data/preferences/halo_preferences.dart';
import '../data/training/training_repository.dart';
import '../data/workouts/workout_repository.dart';

/// Hands the app's long-lived services down the tree.
///
/// An [InheritedWidget] rather than a state-management package: there are a
/// handful of services, none ever changes identity, and the whole job is
/// "reach them from any screen". It carries references only and never
/// rebuilds; the state lives in the services themselves, which are listenable.
///
/// It sits above the `CupertinoApp`, so the tab bodies and every pushed route
/// reach the same instances.
class HaloScope extends InheritedWidget {
  const HaloScope({
    super.key,
    required this.database,
    required this.preferences,
    required this.activity,
    required this.steps,
    required this.workouts,
    required this.nutrition,
    required this.training,
    required super.child,
  });

  final AppDatabase database;
  final HaloPreferences preferences;
  final ActivityStore activity;
  final StepTracker steps;
  final WorkoutRepository workouts;
  final NutritionRepository nutrition;
  final TrainingRepository training;

  static HaloScope _of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HaloScope>();
    assert(scope != null, 'No HaloScope found above this widget.');
    return scope!;
  }

  static AppDatabase databaseOf(BuildContext context) => _of(context).database;

  static HaloPreferences preferencesOf(BuildContext context) =>
      _of(context).preferences;

  static ActivityStore activityOf(BuildContext context) =>
      _of(context).activity;

  static StepTracker stepsOf(BuildContext context) => _of(context).steps;

  static WorkoutRepository workoutsOf(BuildContext context) =>
      _of(context).workouts;

  static NutritionRepository nutritionOf(BuildContext context) =>
      _of(context).nutrition;

  static TrainingRepository trainingOf(BuildContext context) =>
      _of(context).training;

  @override
  bool updateShouldNotify(HaloScope oldWidget) =>
      database != oldWidget.database ||
      preferences != oldWidget.preferences ||
      activity != oldWidget.activity ||
      steps != oldWidget.steps ||
      workouts != oldWidget.workouts ||
      nutrition != oldWidget.nutrition ||
      training != oldWidget.training;
}
