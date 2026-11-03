import 'dart:math' as math;

import 'body_profile.dart';
import 'nutrition.dart';

/// Where the user trains.
enum TrainingPlace {
  gym('Gym'),
  home('Home');

  const TrainingPlace(this.title);

  final String title;
}

/// How much training the body is used to.
enum TrainingLevel {
  beginner('Beginner', 1.0),
  intermediate('Intermediate', 1.4),
  advanced('Advanced', 1.8);

  const TrainingLevel(this.title, this.strength);

  final String title;

  /// Starting loads scale with it.
  final double strength;
}

/// The user's training set-up: where, how experienced, which days.
class TrainingProfile {
  const TrainingProfile({
    this.place = TrainingPlace.gym,
    this.level = TrainingLevel.beginner,
    this.weekdays = const {1, 3, 5},
    this.swaps = const {},
  });

  final TrainingPlace place;
  final TrainingLevel level;

  /// 1 Monday … 7 Sunday.
  final Set<int> weekdays;

  /// Exercises the user swapped in, by the plan's slot
  /// ([PlannedExercise.slot]): one not liked, or without the kit for it.
  final Map<String, String> swaps;

  TrainingProfile copyWith({
    TrainingPlace? place,
    TrainingLevel? level,
    Set<int>? weekdays,
    Map<String, String>? swaps,
  }) => TrainingProfile(
    place: place ?? this.place,
    level: level ?? this.level,
    weekdays: weekdays ?? this.weekdays,
    swaps: swaps ?? this.swaps,
  );

  /// With [exerciseId] in [slot]; null puts the plan's own choice back.
  TrainingProfile swapped(String slot, String? exerciseId) => copyWith(
    swaps: {
      for (final e in swaps.entries)
        if (e.key != slot) e.key: e.value,
      slot: ?exerciseId,
    },
  );

  /// Sensible days for a number of sessions a week.
  static Set<int> defaultDays(int count) => switch (count) {
    <= 2 => {2, 5},
    3 => {1, 3, 5},
    4 => {1, 2, 4, 5},
    5 => {1, 2, 3, 4, 5},
    _ => {1, 2, 3, 4, 5, 6},
  };

  Map<String, Object?> toJson() => {
    'place': place.name,
    'level': level.name,
    'days': (weekdays.toList()..sort()),
    'swaps': swaps,
  };

  static TrainingProfile fromJson(Map<String, Object?> json) => TrainingProfile(
    place: TrainingPlace.values.asNameMap()[json['place']] ?? TrainingPlace.gym,
    level:
        TrainingLevel.values.asNameMap()[json['level']] ??
        TrainingLevel.beginner,
    weekdays: {
      for (final d in (json['days'] as List?) ?? const [1, 3, 5])
        (d as num).toInt(),
    },
    swaps: {
      for (final e in ((json['swaps'] as Map?) ?? const {}).entries)
        e.key as String: e.value as String,
    },
  );
}

/// The movement an exercise trains: a plan is built from patterns, so every
/// week covers the whole body whatever the equipment.
enum Pattern {
  squat,
  hinge,
  lunge,
  pushHorizontal,
  pushVertical,
  pullHorizontal,
  pullVertical,
  arms,
  legs,
  core,
  conditioning,
}

/// How a set is measured.
enum Measure { reps, seconds }

/// One exercise.
///
/// A gym exercise has a load, started from the user's body weight times
/// [ratio] and their level. A home exercise has none; it gets harder by
/// moving to the next exercise of its [ladder] once the top of the rep range
/// comes easily.
class Exercise {
  const Exercise(
    this.id,
    this.name,
    this.pattern, {
    required this.place,
    this.ratio = 0,
    this.lower = false,
    this.dumbbell = false,
    this.measure = Measure.reps,
    this.ladder,
    this.step = 0,
    this.cue = '',
  });

  final String id;
  final String name;
  final Pattern pattern;
  final TrainingPlace place;

  /// Starting load as a share of body weight, for a beginner; 0 for none.
  final double ratio;

  /// Legs: loads go up in bigger steps.
  final bool lower;

  /// Loaded per hand, in dumbbell steps.
  final bool dumbbell;

  final Measure measure;

  /// For home exercises: which progression ladder, and the rung.
  final String? ladder;
  final int step;

  /// One line on doing it well.
  final String cue;

  bool get loaded => ratio > 0;

  /// How long to rest between sets: longest after heavy legs and hips, a
  /// little less after the big upper-body lifts, shortest for small muscles
  /// and the core, and less at home, where the loads are lighter.
  Duration get rest {
    final seconds = switch (pattern) {
      Pattern.squat || Pattern.hinge => loaded ? 150 : 75,
      Pattern.pushHorizontal ||
      Pattern.pushVertical ||
      Pattern.pullHorizontal ||
      Pattern.pullVertical ||
      Pattern.lunge => loaded ? 105 : 60,
      Pattern.arms || Pattern.legs => loaded ? 75 : 45,
      Pattern.core => 45,
      Pattern.conditioning => 30,
    };
    return Duration(seconds: seconds);
  }
}

/// Every exercise the planner can choose from.
abstract final class ExerciseCatalog {
  static const all = <Exercise>[
    // ── Gym ────────────────────────────────────────────────────────────────
    Exercise(
      'back_squat',
      'Barbell Back Squat',
      Pattern.squat,
      place: TrainingPlace.gym,
      ratio: 0.5,
      lower: true,
      cue: 'Brace, sit between the hips, knees over toes.',
    ),
    Exercise(
      'goblet_squat',
      'Goblet Squat',
      Pattern.squat,
      place: TrainingPlace.gym,
      ratio: 0.2,
      lower: true,
      cue: 'Dumbbell at the chest, elbows inside the knees.',
    ),
    Exercise(
      'romanian_deadlift',
      'Romanian Deadlift',
      Pattern.hinge,
      place: TrainingPlace.gym,
      ratio: 0.5,
      lower: true,
      cue: 'Soft knees, push the hips back, bar close to the legs.',
    ),
    Exercise(
      'hip_thrust',
      'Barbell Hip Thrust',
      Pattern.hinge,
      place: TrainingPlace.gym,
      ratio: 0.6,
      lower: true,
      cue: 'Chin tucked, squeeze at the top for a second.',
    ),
    Exercise(
      'leg_press',
      'Leg Press',
      Pattern.lunge,
      place: TrainingPlace.gym,
      ratio: 1.0,
      lower: true,
      cue: 'Lower until the hips start to tuck, then drive.',
    ),
    Exercise(
      'db_lunge',
      'Dumbbell Walking Lunge',
      Pattern.lunge,
      place: TrainingPlace.gym,
      ratio: 0.1,
      lower: true,
      dumbbell: true,
      cue: 'Long step, back knee to the floor.',
    ),
    Exercise(
      'bench_press',
      'Barbell Bench Press',
      Pattern.pushHorizontal,
      place: TrainingPlace.gym,
      ratio: 0.45,
      cue: 'Shoulder blades back, bar to the lower chest.',
    ),
    Exercise(
      'db_bench',
      'Dumbbell Bench Press',
      Pattern.pushHorizontal,
      place: TrainingPlace.gym,
      ratio: 0.15,
      dumbbell: true,
      cue: 'Elbows at 45°, full stretch at the bottom.',
    ),
    Exercise(
      'overhead_press',
      'Overhead Press',
      Pattern.pushVertical,
      place: TrainingPlace.gym,
      ratio: 0.3,
      cue: 'Squeeze the glutes, press straight up past the face.',
    ),
    Exercise(
      'db_shoulder_press',
      'Dumbbell Shoulder Press',
      Pattern.pushVertical,
      place: TrainingPlace.gym,
      ratio: 0.1,
      dumbbell: true,
      cue: 'Seated, back supported, no arching.',
    ),
    Exercise(
      'barbell_row',
      'Barbell Row',
      Pattern.pullHorizontal,
      place: TrainingPlace.gym,
      ratio: 0.4,
      cue: 'Hinge to 45°, pull to the belly button.',
    ),
    Exercise(
      'cable_row',
      'Seated Cable Row',
      Pattern.pullHorizontal,
      place: TrainingPlace.gym,
      ratio: 0.4,
      cue: 'Chest up, elbows past the ribs.',
    ),
    Exercise(
      'lat_pulldown',
      'Lat Pulldown',
      Pattern.pullVertical,
      place: TrainingPlace.gym,
      ratio: 0.45,
      cue: 'Pull to the upper chest, lean back slightly.',
    ),
    Exercise(
      'assisted_pullup',
      'Assisted Pull-up',
      Pattern.pullVertical,
      place: TrainingPlace.gym,
      ratio: 0.3,
      cue: 'Less assistance is progress: the load here is the help.',
    ),
    Exercise(
      'db_curl',
      'Dumbbell Curl',
      Pattern.arms,
      place: TrainingPlace.gym,
      ratio: 0.07,
      dumbbell: true,
      cue: 'Elbows still, slow on the way down.',
    ),
    Exercise(
      'triceps_pushdown',
      'Triceps Pushdown',
      Pattern.arms,
      place: TrainingPlace.gym,
      ratio: 0.15,
      cue: 'Elbows at the sides, lock out fully.',
    ),
    Exercise(
      'leg_curl',
      'Lying Leg Curl',
      Pattern.legs,
      place: TrainingPlace.gym,
      ratio: 0.25,
      lower: true,
      cue: 'Hips down on the pad, control the return.',
    ),
    Exercise(
      'calf_raise',
      'Standing Calf Raise',
      Pattern.legs,
      place: TrainingPlace.gym,
      ratio: 0.6,
      lower: true,
      cue: 'Full stretch, pause at the top.',
    ),
    Exercise(
      'cable_crunch',
      'Cable Crunch',
      Pattern.core,
      place: TrainingPlace.gym,
      ratio: 0.3,
      cue: 'Round the spine, do not sit back.',
    ),
    Exercise(
      'plank',
      'Plank',
      Pattern.core,
      place: TrainingPlace.gym,
      measure: Measure.seconds,
      cue: 'Ribs down, squeeze the glutes.',
    ),
    // Alternatives, for swapping one in: other kit, or none.
    Exercise(
      'front_squat',
      'Barbell Front Squat',
      Pattern.squat,
      place: TrainingPlace.gym,
      ratio: 0.4,
      lower: true,
      cue: 'Elbows high, sit straight down.',
    ),
    Exercise(
      'hack_squat',
      'Hack Squat Machine',
      Pattern.squat,
      place: TrainingPlace.gym,
      ratio: 0.6,
      lower: true,
      cue: 'Feet mid-platform, knees track the toes.',
    ),
    Exercise(
      'smith_squat',
      'Smith Machine Squat',
      Pattern.squat,
      place: TrainingPlace.gym,
      ratio: 0.45,
      lower: true,
      cue: 'Feet a little forward, chest up.',
    ),
    Exercise(
      'deadlift',
      'Deadlift',
      Pattern.hinge,
      place: TrainingPlace.gym,
      ratio: 0.7,
      lower: true,
      cue: 'Bar over mid-foot, push the floor away.',
    ),
    Exercise(
      'trap_bar_deadlift',
      'Trap Bar Deadlift',
      Pattern.hinge,
      place: TrainingPlace.gym,
      ratio: 0.75,
      lower: true,
      cue: 'Hips and chest rise together.',
    ),
    Exercise(
      'kb_swing',
      'Kettlebell Swing',
      Pattern.hinge,
      place: TrainingPlace.gym,
      ratio: 0.2,
      lower: true,
      dumbbell: true,
      cue: 'Snap the hips; the arms only guide.',
    ),
    Exercise(
      'bulgarian_db',
      'Dumbbell Bulgarian Split Squat',
      Pattern.lunge,
      place: TrainingPlace.gym,
      ratio: 0.1,
      lower: true,
      dumbbell: true,
      cue: 'Rear foot on the bench, front shin upright.',
    ),
    Exercise(
      'db_step_up',
      'Dumbbell Step-up',
      Pattern.lunge,
      place: TrainingPlace.gym,
      ratio: 0.1,
      lower: true,
      dumbbell: true,
      cue: 'Drive through the front heel.',
    ),
    Exercise(
      'incline_db_press',
      'Incline Dumbbell Press',
      Pattern.pushHorizontal,
      place: TrainingPlace.gym,
      ratio: 0.13,
      dumbbell: true,
      cue: 'Bench at 30°, elbows at 45°.',
    ),
    Exercise(
      'machine_chest_press',
      'Machine Chest Press',
      Pattern.pushHorizontal,
      place: TrainingPlace.gym,
      ratio: 0.4,
      cue: 'Handles at mid-chest, slow on the way back.',
    ),
    Exercise(
      'gym_pushup',
      'Push-up',
      Pattern.pushHorizontal,
      place: TrainingPlace.gym,
      cue: 'Body in one line, chest to the floor.',
    ),
    Exercise(
      'machine_shoulder_press',
      'Machine Shoulder Press',
      Pattern.pushVertical,
      place: TrainingPlace.gym,
      ratio: 0.25,
      cue: 'Seat so the handles start at the shoulders.',
    ),
    Exercise(
      'arnold_press',
      'Arnold Press',
      Pattern.pushVertical,
      place: TrainingPlace.gym,
      ratio: 0.08,
      dumbbell: true,
      cue: 'Turn the palms out as you press.',
    ),
    Exercise(
      'one_arm_db_row',
      'One-arm Dumbbell Row',
      Pattern.pullHorizontal,
      place: TrainingPlace.gym,
      ratio: 0.2,
      dumbbell: true,
      cue: 'Pull to the hip, not the chest.',
    ),
    Exercise(
      'chest_supported_row',
      'Chest-supported Row',
      Pattern.pullHorizontal,
      place: TrainingPlace.gym,
      ratio: 0.35,
      cue: 'Chest on the pad, squeeze the shoulder blades.',
    ),
    Exercise(
      'inverted_row',
      'Inverted Row',
      Pattern.pullHorizontal,
      place: TrainingPlace.gym,
      cue: 'Bar at hip height, body straight.',
    ),
    Exercise(
      'pullup',
      'Pull-up',
      Pattern.pullVertical,
      place: TrainingPlace.gym,
      cue: 'From a dead hang, chin over the bar.',
    ),
    Exercise(
      'close_grip_pulldown',
      'Close-grip Pulldown',
      Pattern.pullVertical,
      place: TrainingPlace.gym,
      ratio: 0.4,
      cue: 'Lean back a little, elbows to the ribs.',
    ),
    Exercise(
      'hammer_curl',
      'Hammer Curl',
      Pattern.arms,
      place: TrainingPlace.gym,
      ratio: 0.08,
      dumbbell: true,
      cue: 'Thumbs up, elbows still.',
    ),
    Exercise(
      'overhead_triceps',
      'Overhead Triceps Extension',
      Pattern.arms,
      place: TrainingPlace.gym,
      ratio: 0.12,
      dumbbell: true,
      cue: 'Elbows forward, full stretch.',
    ),
    Exercise(
      'ez_curl',
      'EZ-bar Curl',
      Pattern.arms,
      place: TrainingPlace.gym,
      ratio: 0.2,
      cue: 'No swinging; lower slowly.',
    ),
    Exercise(
      'leg_extension',
      'Leg Extension',
      Pattern.legs,
      place: TrainingPlace.gym,
      ratio: 0.3,
      lower: true,
      cue: 'Pause with the legs straight.',
    ),
    Exercise(
      'seated_leg_curl',
      'Seated Leg Curl',
      Pattern.legs,
      place: TrainingPlace.gym,
      ratio: 0.3,
      lower: true,
      cue: 'Hips down, curl all the way.',
    ),
    Exercise(
      'hanging_knee_raise',
      'Hanging Knee Raise',
      Pattern.core,
      place: TrainingPlace.gym,
      cue: 'Curl the hips up, no swinging.',
    ),
    Exercise(
      'ab_wheel',
      'Ab Wheel Rollout',
      Pattern.core,
      place: TrainingPlace.gym,
      cue: 'Only as far as the back stays flat.',
    ),
    Exercise(
      'bike_intervals',
      'Bike Intervals',
      Pattern.conditioning,
      place: TrainingPlace.gym,
      measure: Measure.seconds,
      cue: '30 s hard, 30 s easy.',
    ),

    // ── Home: ladders from easier to harder ────────────────────────────────
    Exercise(
      'bw_squat',
      'Bodyweight Squat',
      Pattern.squat,
      place: TrainingPlace.home,
      ladder: 'squat',
      step: 0,
      cue: 'Heels down, sit as deep as is comfortable.',
    ),
    Exercise(
      'split_squat',
      'Split Squat',
      Pattern.squat,
      place: TrainingPlace.home,
      ladder: 'squat',
      step: 1,
      cue: 'Long stance, front heel planted.',
    ),
    Exercise(
      'bulgarian_split_squat',
      'Bulgarian Split Squat',
      Pattern.squat,
      place: TrainingPlace.home,
      ladder: 'squat',
      step: 2,
      cue: 'Back foot on a chair or sofa.',
    ),
    Exercise(
      'shrimp_squat',
      'Shrimp Squat',
      Pattern.squat,
      place: TrainingPlace.home,
      ladder: 'squat',
      step: 3,
      cue: 'Hold the back foot, knee to the floor.',
    ),
    Exercise(
      'glute_bridge',
      'Glute Bridge',
      Pattern.hinge,
      place: TrainingPlace.home,
      ladder: 'hinge',
      step: 0,
      cue: 'Drive through the heels, squeeze at the top.',
    ),
    Exercise(
      'single_leg_bridge',
      'Single-leg Glute Bridge',
      Pattern.hinge,
      place: TrainingPlace.home,
      ladder: 'hinge',
      step: 1,
      cue: 'Hips level the whole way.',
    ),
    Exercise(
      'single_leg_rdl',
      'Single-leg Romanian Deadlift',
      Pattern.hinge,
      place: TrainingPlace.home,
      ladder: 'hinge',
      step: 2,
      cue: 'Reach long, hips square to the floor.',
    ),
    Exercise(
      'reverse_lunge',
      'Reverse Lunge',
      Pattern.lunge,
      place: TrainingPlace.home,
      ladder: 'lunge',
      step: 0,
      cue: 'Step back, front knee over the ankle.',
    ),
    Exercise(
      'walking_lunge',
      'Walking Lunge',
      Pattern.lunge,
      place: TrainingPlace.home,
      ladder: 'lunge',
      step: 1,
      cue: 'Upright, steady steps.',
    ),
    Exercise(
      'jump_lunge',
      'Jumping Lunge',
      Pattern.lunge,
      place: TrainingPlace.home,
      ladder: 'lunge',
      step: 2,
      cue: 'Land softly, switch in the air.',
    ),
    Exercise(
      'incline_pushup',
      'Incline Push-up',
      Pattern.pushHorizontal,
      place: TrainingPlace.home,
      ladder: 'push',
      step: 0,
      cue: 'Hands on a table or bench, body straight.',
    ),
    Exercise(
      'pushup',
      'Push-up',
      Pattern.pushHorizontal,
      place: TrainingPlace.home,
      ladder: 'push',
      step: 1,
      cue: 'Chest to the floor, elbows at 45°.',
    ),
    Exercise(
      'decline_pushup',
      'Decline Push-up',
      Pattern.pushHorizontal,
      place: TrainingPlace.home,
      ladder: 'push',
      step: 2,
      cue: 'Feet on a chair.',
    ),
    Exercise(
      'archer_pushup',
      'Archer Push-up',
      Pattern.pushHorizontal,
      place: TrainingPlace.home,
      ladder: 'push',
      step: 3,
      cue: 'One arm bends, the other stays long.',
    ),
    Exercise(
      'pike_pushup',
      'Pike Push-up',
      Pattern.pushVertical,
      place: TrainingPlace.home,
      ladder: 'overhead',
      step: 0,
      cue: 'Hips high, head between the hands.',
    ),
    Exercise(
      'elevated_pike_pushup',
      'Elevated Pike Push-up',
      Pattern.pushVertical,
      place: TrainingPlace.home,
      ladder: 'overhead',
      step: 1,
      cue: 'Feet on a chair, hips over the shoulders.',
    ),
    Exercise(
      'table_row',
      'Table Row',
      Pattern.pullHorizontal,
      place: TrainingPlace.home,
      ladder: 'row',
      step: 0,
      cue: 'Under a sturdy table, pull the chest to the edge.',
    ),
    Exercise(
      'feet_elevated_row',
      'Feet-elevated Table Row',
      Pattern.pullHorizontal,
      place: TrainingPlace.home,
      ladder: 'row',
      step: 1,
      cue: 'Feet on a chair, body straight.',
    ),
    Exercise(
      'prone_ytw',
      'Prone Y-T-W Raise',
      Pattern.pullVertical,
      place: TrainingPlace.home,
      ladder: 'pull',
      step: 0,
      cue: 'Face down, thumbs up, squeeze the shoulder blades.',
    ),
    Exercise(
      'door_pullup_negative',
      'Pull-up Negative',
      Pattern.pullVertical,
      place: TrainingPlace.home,
      ladder: 'pull',
      step: 1,
      cue: 'Jump up, lower for five seconds. Needs a door bar.',
    ),
    Exercise(
      'chair_dip',
      'Chair Dip',
      Pattern.arms,
      place: TrainingPlace.home,
      ladder: 'dip',
      step: 0,
      cue: 'Shoulders down, elbows back.',
    ),
    Exercise(
      'diamond_pushup',
      'Diamond Push-up',
      Pattern.arms,
      place: TrainingPlace.home,
      ladder: 'dip',
      step: 1,
      cue: 'Hands together under the chest.',
    ),
    Exercise(
      'calf_raise_home',
      'Single-leg Calf Raise',
      Pattern.legs,
      place: TrainingPlace.home,
      ladder: 'calf',
      step: 0,
      cue: 'On a step, full range.',
    ),
    Exercise(
      'dead_bug',
      'Dead Bug',
      Pattern.core,
      place: TrainingPlace.home,
      ladder: 'core',
      step: 0,
      cue: 'Lower back pressed down the whole time.',
    ),
    Exercise(
      'plank_home',
      'Plank',
      Pattern.core,
      place: TrainingPlace.home,
      measure: Measure.seconds,
      ladder: 'core',
      step: 1,
      cue: 'Ribs down, squeeze the glutes.',
    ),
    Exercise(
      'hollow_hold',
      'Hollow Hold',
      Pattern.core,
      place: TrainingPlace.home,
      measure: Measure.seconds,
      ladder: 'core',
      step: 2,
      cue: 'Arms overhead, legs low, back flat.',
    ),
    Exercise(
      'burpee_intervals',
      'Burpee Intervals',
      Pattern.conditioning,
      place: TrainingPlace.home,
      measure: Measure.seconds,
      cue: '30 s on, 30 s off.',
    ),
  ];

  static Exercise byId(String id) => all.firstWhere((e) => e.id == id);

  static Exercise? tryId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// What [current] can be swapped for: the same movement in the same
  /// place, the rest of the catalogue's way to train it.
  static List<Exercise> alternatives(Exercise current) => [
    for (final e in all)
      if (e.pattern == current.pattern &&
          e.place == current.place &&
          e.id != current.id)
        e,
  ];

  /// The rungs of a home ladder, easiest first.
  static List<Exercise> ladder(String name) =>
      all.where((e) => e.ladder == name).toList()
        ..sort((a, b) => a.step.compareTo(b.step));
}

/// One completed set, as logged.
class SetLog {
  const SetLog({
    required this.time,
    required this.exerciseId,
    required this.reps,
    this.kg,
  });

  /// When the session it belongs to started: sets of one session share it.
  final DateTime time;
  final String exerciseId;

  /// Reps, or seconds for a hold.
  final int reps;
  final double? kg;
}

/// An exercise as planned for a session: how many sets, in what range, at
/// what load.
class PlannedExercise {
  const PlannedExercise({
    required this.exercise,
    required this.sets,
    required this.min,
    required this.max,
    this.kg,
    this.change = 0,
    this.slot = '',
    this.swapped = false,
  });

  final Exercise exercise;
  final int sets;

  /// Its place in the session's template, which a swap is kept against:
  /// "squat:0".
  final String slot;

  /// The user's choice rather than the plan's.
  final bool swapped;

  /// Reps (or seconds) to aim between.
  final int min;
  final int max;

  /// The load, for a gym exercise.
  final double? kg;

  /// Load since last time: up, the same, or down after a hard session.
  final double change;

  String get target {
    final unit = exercise.measure == Measure.seconds ? ' s' : '';
    final range = min == max ? '$min' : '$min–$max';
    final load = kg == null ? '' : ' · ${_kg(kg!)} kg';
    return '$sets × $range$unit$load';
  }

  static String _kg(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
}

/// A training day.
class PlannedSession {
  const PlannedSession({
    required this.weekday,
    required this.title,
    required this.exercises,
  });

  final int weekday;
  final String title;
  final List<PlannedExercise> exercises;

  /// About how long it takes: sets, rest and the finisher.
  Duration get length {
    var minutes = 0.0;
    for (final e in exercises) {
      minutes += e.exercise.pattern == Pattern.conditioning
          ? 10
          : e.sets * (e.exercise.loaded ? 2.5 : 1.75);
    }
    return Duration(minutes: (minutes / 5).round() * 5 + 5);
  }
}

/// Builds the week and progresses every exercise from what was logged.
///
/// - Sessions by days a week: two or three full-body days, four as upper and
///   lower twice, five with a full-body day between.
/// - Losing weight adds a ten-minute conditioning finisher; gaining keeps the
///   rep ranges lower for heavier loads.
/// - Gym loads use double progression: when every set reached the top of the
///   range last time, the load goes up (2.5 kg, 5 kg for legs, 2 kg a hand
///   for dumbbells); when sets fell short of the bottom twice running, it
///   comes down 10%; otherwise it stays, and the reps climb.
/// - At home the same rule moves to the next, harder exercise of the ladder
///   instead of adding weight.
abstract final class TrainingPlanner {
  static List<PlannedSession> week({
    required TrainingProfile training,
    required BodyProfile body,
    required WeightGoal goal,
    required List<SetLog> history,
  }) {
    final days = training.weekdays.toList()..sort();
    final templates = _templates(days.length);
    final losing =
        goal.targetKg != null && goal.targetKg! < body.weightKg - 0.5;
    final gaining =
        goal.targetKg != null && goal.targetKg! > body.weightKg + 0.5;

    return [
      for (var i = 0; i < days.length; i++)
        PlannedSession(
          weekday: days[i],
          title: templates[i].$1,
          exercises: [
            for (final (pattern, variant) in [
              ...templates[i].$2,
              if (losing) (Pattern.conditioning, 0),
            ])
              ?_plan(
                pattern,
                variant,
                training: training,
                body: body,
                gaining: gaining,
                history: history,
              ),
          ],
        ),
    ];
  }

  /// Session names and the patterns in them; the second number picks the
  /// first or second exercise for the pattern, so A and B days differ.
  static List<(String, List<(Pattern, int)>)> _templates(int count) {
    const fullA = (
      'Full Body A',
      [
        (Pattern.squat, 0),
        (Pattern.pushHorizontal, 0),
        (Pattern.pullHorizontal, 0),
        (Pattern.hinge, 1),
        (Pattern.core, 0),
      ],
    );
    const fullB = (
      'Full Body B',
      [
        (Pattern.hinge, 0),
        (Pattern.pushVertical, 0),
        (Pattern.pullVertical, 0),
        (Pattern.lunge, 0),
        (Pattern.core, 1),
      ],
    );
    const upperA = (
      'Upper A',
      [
        (Pattern.pushHorizontal, 0),
        (Pattern.pullHorizontal, 0),
        (Pattern.pushVertical, 1),
        (Pattern.pullVertical, 0),
        (Pattern.arms, 0),
      ],
    );
    const lowerA = (
      'Lower A',
      [
        (Pattern.squat, 0),
        (Pattern.hinge, 0),
        (Pattern.lunge, 1),
        (Pattern.legs, 0),
        (Pattern.core, 0),
      ],
    );
    const upperB = (
      'Upper B',
      [
        (Pattern.pushVertical, 0),
        (Pattern.pullVertical, 1),
        (Pattern.pushHorizontal, 1),
        (Pattern.pullHorizontal, 1),
        (Pattern.arms, 1),
      ],
    );
    const lowerB = (
      'Lower B',
      [
        (Pattern.hinge, 1),
        (Pattern.squat, 1),
        (Pattern.lunge, 0),
        (Pattern.legs, 1),
        (Pattern.core, 1),
      ],
    );
    return switch (count) {
      0 => const [],
      1 => const [fullA],
      2 => const [fullA, fullB],
      3 => const [fullA, fullB, fullA],
      4 => const [upperA, lowerA, upperB, lowerB],
      5 => const [upperA, lowerA, fullB, upperB, lowerB],
      _ => const [upperA, lowerA, fullA, upperB, lowerB, fullB],
    };
  }

  static PlannedExercise? _plan(
    Pattern pattern,
    int variant, {
    required TrainingProfile training,
    required BodyProfile body,
    required bool gaining,
    required List<SetLog> history,
  }) {
    final options = ExerciseCatalog.all
        .where((e) => e.pattern == pattern && e.place == training.place)
        .toList();
    if (options.isEmpty) return null;

    // The user's own choice for this slot, if it still fits it.
    final slot = '${pattern.name}:$variant';
    final chosen = training.swaps[slot];
    final swap = chosen == null ? null : ExerciseCatalog.tryId(chosen);
    final swapped =
        swap != null && swap.pattern == pattern && swap.place == training.place
        ? swap
        : null;

    final level = training.level;
    final sets = switch (level) {
      TrainingLevel.beginner => 3,
      TrainingLevel.intermediate => pattern == Pattern.core ? 3 : 4,
      TrainingLevel.advanced => 4,
    };

    if (pattern == Pattern.conditioning) {
      return PlannedExercise(
        exercise: swapped ?? options.first,
        slot: slot,
        swapped: swapped != null,
        sets: switch (level) {
          TrainingLevel.beginner => 6,
          TrainingLevel.intermediate => 8,
          TrainingLevel.advanced => 10,
        },
        min: 30,
        max: 30,
      );
    }

    if (training.place == TrainingPlace.home) {
      return _homePlan(
        options,
        variant,
        sets: sets,
        level: level,
        history: history,
        slot: slot,
        swapped: swapped,
      );
    }

    final exercise = swapped ?? options[variant.clamp(0, options.length - 1)];
    final compound = !{
      Pattern.arms,
      Pattern.legs,
      Pattern.core,
    }.contains(pattern);
    if (exercise.measure == Measure.seconds) {
      return PlannedExercise(
        exercise: exercise,
        sets: 3,
        min: 30,
        max: 60,
        slot: slot,
        swapped: swapped != null,
      );
    }
    final (min, max) = compound ? (gaining ? (6, 10) : (8, 12)) : (10, 15);
    // Body weight only (pull-ups, push-ups): the reps climb, no load.
    if (!exercise.loaded) {
      return PlannedExercise(
        exercise: exercise,
        sets: sets,
        min: math.max(3, min - 2),
        max: max + 3,
        slot: slot,
        swapped: swapped != null,
      );
    }
    final (kg, change) = _load(exercise, body, level, history, min, max);
    return PlannedExercise(
      slot: slot,
      swapped: swapped != null,
      exercise: exercise,
      sets: sets,
      min: min,
      max: max,
      kg: kg,
      change: change,
    );
  }

  static PlannedExercise _homePlan(
    List<Exercise> options,
    int variant, {
    required int sets,
    required TrainingLevel level,
    required List<SetLog> history,
    required String slot,
    Exercise? swapped,
  }) {
    // The ladder for this pattern; variant picks between ladders where a
    // pattern has two. A swapped exercise brings its own ladder, and starts
    // on its own rung.
    final ladders = {for (final e in options) ?e.ladder}.toList();
    final ladderName =
        swapped?.ladder ??
        (ladders.isEmpty
            ? null
            : ladders[variant.clamp(0, ladders.length - 1)]);
    final rungs = ladderName == null
        ? options
        : ExerciseCatalog.ladder(ladderName);

    // Where the user stands on the ladder: the last rung trained, moved up
    // when it was mastered; otherwise a start by level.
    var rung =
        (swapped != null && rungs.contains(swapped)
                ? rungs.indexOf(swapped)
                : switch (level) {
                    TrainingLevel.beginner => 0,
                    TrainingLevel.intermediate => 1,
                    TrainingLevel.advanced => 2,
                  })
            .clamp(0, rungs.length - 1);
    for (var i = rungs.length - 1; i >= 0; i--) {
      final sessions = _sessions(history, rungs[i].id);
      if (sessions.isEmpty) continue;
      rung = i;
      final top = rungs[i].measure == Measure.seconds ? 60 : 15;
      if (sessions.first.every((s) => s.reps >= top) && i < rungs.length - 1) {
        rung = i + 1;
      }
      break;
    }
    final exercise = rungs[rung];
    final seconds = exercise.measure == Measure.seconds;
    return PlannedExercise(
      slot: slot,
      swapped: swapped != null,
      exercise: exercise,
      sets: sets,
      min: seconds ? 20 : 8,
      max: seconds ? 60 : 15,
    );
  }

  /// The load for a gym exercise from its history, or a starting load.
  static (double, double) _load(
    Exercise exercise,
    BodyProfile body,
    TrainingLevel level,
    List<SetLog> history,
    int min,
    int max,
  ) {
    final sessions = _sessions(history, exercise.id);
    final step = exercise.dumbbell
        ? 2.0
        : exercise.lower
        ? 5.0
        : 2.5;
    if (sessions.isEmpty) {
      final start = body.weightKg * exercise.ratio * level.strength;
      return (math.max(step, _round(start, step)), 0);
    }
    final last = sessions.first;
    final current = last.map((s) => s.kg ?? 0).reduce(math.max);
    if (last.every((s) => s.reps >= max)) {
      return (current + step, step);
    }
    final shortTwice =
        sessions.length >= 2 &&
        sessions.take(2).every((sets) => sets.any((s) => s.reps < min));
    if (shortTwice) {
      final down = math.max(step, _round(current * 0.9, step));
      return (down, down - current);
    }
    return (current, 0);
  }

  /// The sets of each past session of an exercise, newest session first.
  static List<List<SetLog>> _sessions(List<SetLog> history, String id) {
    final byTime = <DateTime, List<SetLog>>{};
    for (final s in history) {
      if (s.exerciseId == id) (byTime[s.time] ??= []).add(s);
    }
    final times = byTime.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final t in times) byTime[t]!];
  }

  static double _round(double v, double step) => (v / step).round() * step;
}
