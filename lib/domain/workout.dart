import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

import 'route.dart';

/// The kinds of workout Halo can record, with what the phone can measure for
/// each.
///
/// [met] is the activity's metabolic equivalent from the Compendium of
/// Physical Activities, rounded to typical effort: active energy is
/// `(met − 1) × kg × hours`, the energy above resting.
enum WorkoutType {
  outdoorWalk(
    'Outdoor Walk',
    Icons.directions_walk_rounded,
    3.5,
    steps: true,
    gps: true,
  ),
  outdoorRun(
    'Outdoor Run',
    Icons.directions_run_rounded,
    9.8,
    steps: true,
    gps: true,
  ),
  indoorWalk('Indoor Walk', Icons.directions_walk_rounded, 3.5, steps: true),
  indoorRun('Indoor Run', Icons.directions_run_rounded, 9.8, steps: true),
  hiking('Hiking', Icons.hiking_rounded, 6.0, steps: true, gps: true),
  outdoorCycle('Outdoor Cycle', Icons.directions_bike_rounded, 7.5, gps: true),
  indoorCycle('Indoor Cycle', Icons.pedal_bike_rounded, 6.8),
  strength('Strength', Icons.fitness_center_rounded, 5.0),
  hiit('HIIT', Icons.local_fire_department_rounded, 8.0),
  yoga('Yoga', Icons.self_improvement_rounded, 2.5),
  pilates('Pilates', Icons.accessibility_new_rounded, 3.0),
  dance('Dance', Icons.music_note_rounded, 5.5),
  swimming('Swimming', Icons.pool_rounded, 7.0),
  rowing('Rowing', Icons.rowing_rounded, 7.0),
  elliptical('Elliptical', Icons.directions_walk_rounded, 5.0),
  other('Other', Icons.sports_rounded, 4.0);

  const WorkoutType(
    this.title,
    this.icon,
    this.met, {
    this.steps = false,
    this.gps = false,
  });

  final String title;
  final IconData icon;
  final double met;

  /// Counted in steps: distance comes from the step counter, and the steps
  /// already fill the Move ring on their own.
  final bool steps;

  /// Outdoors: the route is followed by GPS, which gives the distance, the
  /// pace, the climb and the map.
  final bool gps;

  /// Whether a distance goal makes sense for it.
  bool get hasDistance => steps || gps;

  static WorkoutType? byName(String name) =>
      WorkoutType.values.asNameMap()[name];
}

/// What a workout is aiming for.
enum WorkoutGoalKind {
  open('Open'),
  time('Time'),
  distance('Distance'),
  calories('Calories');

  const WorkoutGoalKind(this.label);

  final String label;
}

/// A goal and its target: minutes, kilometres or kilocalories.
class WorkoutGoal {
  const WorkoutGoal(this.kind, [this.target = 0]);

  static const open = WorkoutGoal(WorkoutGoalKind.open);

  final WorkoutGoalKind kind;
  final double target;

  /// Progress towards the goal, 0 to 1, or null for an open goal.
  double? progress({
    required Duration elapsed,
    required double distanceKm,
    required double kcal,
  }) {
    if (target <= 0) return null;
    return switch (kind) {
      WorkoutGoalKind.open => null,
      WorkoutGoalKind.time => elapsed.inSeconds / (target * 60),
      WorkoutGoalKind.distance => distanceKm / target,
      WorkoutGoalKind.calories => kcal / target,
    };
  }

  String get describe => switch (kind) {
    WorkoutGoalKind.open => 'Open Goal',
    WorkoutGoalKind.time => '${target.round()} min',
    WorkoutGoalKind.distance => '${target.toStringAsFixed(1)} km',
    WorkoutGoalKind.calories => '${target.round()} kcal',
  };
}

/// A finished workout, as stored.
class WorkoutRecord {
  const WorkoutRecord({
    this.id,
    required this.type,
    required this.start,
    required this.end,
    required this.activeDuration,
    required this.distanceKm,
    required this.activeKcal,
    required this.steps,
    this.effort,
    this.elevationGainM = 0,
    this.route = const [],
  });

  final int? id;
  final WorkoutType type;
  final DateTime start;
  final DateTime end;

  /// Time spent moving: the span from start to end less the pauses.
  final Duration activeDuration;

  final double distanceKm;
  final double activeKcal;
  final int steps;

  /// How hard it felt, 1 to 10, if the user said.
  final int? effort;

  /// Metres climbed, for a GPS workout.
  final double elevationGainM;

  /// The route, for a GPS workout. Empty in lists, where it is not read; a
  /// workout's detail loads it separately.
  final List<RoutePoint> route;

  WorkoutRecord withRoute(List<RoutePoint> route) => WorkoutRecord(
    id: id,
    type: type,
    start: start,
    end: end,
    activeDuration: activeDuration,
    distanceKm: distanceKm,
    activeKcal: activeKcal,
    steps: steps,
    effort: effort,
    elevationGainM: elevationGainM,
    route: route,
  );
}
