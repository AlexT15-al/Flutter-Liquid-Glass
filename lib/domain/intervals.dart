import 'workout.dart';

/// What a stretch of a custom workout is for.
enum StepKind {
  warmup('Warm Up'),
  work('Work'),
  recover('Recover'),
  cooldown('Cool Down');

  const StepKind(this.title);

  final String title;
}

/// How a step ends: after a time, or after a distance.
enum StepMeasure { time, distance }

/// One stretch: a kind, and how long, in seconds or metres.
class IntervalStep {
  const IntervalStep(this.kind, this.measure, this.value);

  final StepKind kind;
  final StepMeasure measure;

  /// Seconds for [StepMeasure.time], metres for [StepMeasure.distance].
  final int value;

  IntervalStep copyWith({StepMeasure? measure, int? value}) =>
      IntervalStep(kind, measure ?? this.measure, value ?? this.value);

  /// "2 min", "400 m", "1.5 km".
  String get describe => switch (measure) {
    StepMeasure.time => describeSeconds(value),
    StepMeasure.distance => describeMetres(value),
  };

  static String describeSeconds(int s) {
    final m = s ~/ 60, r = s % 60;
    if (m == 0) return '$r s';
    if (r == 0) return '$m min';
    return '$m:${r.toString().padLeft(2, '0')} min';
  }

  static String describeMetres(int m) {
    if (m < 1000) return '$m m';
    final km = m / 1000;
    return '${km == km.roundToDouble() ? km.round() : km.toStringAsFixed(1)} km';
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'measure': measure.name,
    'value': value,
  };

  static IntervalStep fromJson(Map<String, Object?> json) => IntervalStep(
    StepKind.values.byName(json['kind'] as String),
    StepMeasure.values.byName(json['measure'] as String),
    (json['value'] as num).toInt(),
  );
}

/// Work and recovery, repeated: "8 × 400 m, 2 min easy".
class IntervalBlock {
  const IntervalBlock({
    required this.repeats,
    required this.work,
    this.recover,
  });

  final int repeats;
  final IntervalStep work;
  final IntervalStep? recover;

  IntervalBlock copyWith({
    int? repeats,
    IntervalStep? work,
    IntervalStep? Function()? recover,
  }) => IntervalBlock(
    repeats: repeats ?? this.repeats,
    work: work ?? this.work,
    recover: recover == null ? this.recover : recover(),
  );

  String get describe =>
      '$repeats × ${work.describe}'
      '${recover == null ? '' : ' · ${recover!.describe} recover'}';

  Map<String, Object?> toJson() => {
    'repeats': repeats,
    'work': work.toJson(),
    'recover': recover?.toJson(),
  };

  static IntervalBlock fromJson(Map<String, Object?> json) => IntervalBlock(
    repeats: (json['repeats'] as num).toInt(),
    work: IntervalStep.fromJson((json['work'] as Map).cast()),
    recover: json['recover'] == null
        ? null
        : IntervalStep.fromJson((json['recover'] as Map).cast()),
  );
}

/// A workout of the user's own: a warm-up, blocks of intervals, a cool-down.
class CustomWorkout {
  const CustomWorkout({
    required this.id,
    required this.name,
    required this.type,
    this.warmup,
    required this.blocks,
    this.cooldown,
  });

  /// Stable across edits: when it was first made, in milliseconds.
  final int id;
  final String name;
  final WorkoutType type;
  final IntervalStep? warmup;
  final List<IntervalBlock> blocks;
  final IntervalStep? cooldown;

  CustomWorkout copyWith({
    String? name,
    WorkoutType? type,
    IntervalStep? Function()? warmup,
    List<IntervalBlock>? blocks,
    IntervalStep? Function()? cooldown,
  }) => CustomWorkout(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    warmup: warmup == null ? this.warmup : warmup(),
    blocks: blocks ?? this.blocks,
    cooldown: cooldown == null ? this.cooldown : cooldown(),
  );

  /// Every step in order, each repeat spelled out.
  List<Segment> get segments {
    final out = <Segment>[];
    if (warmup case final w?) out.add(Segment(w, 'Warm Up'));
    for (var b = 0; b < blocks.length; b++) {
      final block = blocks[b];
      for (var r = 0; r < block.repeats; r++) {
        final of = block.repeats > 1 ? ' ${r + 1} of ${block.repeats}' : '';
        out.add(Segment(block.work, 'Work$of'));
        // No recovery after the last repeat of the last block when a
        // cool-down follows: it would be a second, shorter cool-down.
        final lastOfAll = b == blocks.length - 1 && r == block.repeats - 1;
        if (block.recover case final rec?
            when !(lastOfAll && cooldown != null)) {
          out.add(Segment(rec, 'Recover$of'));
        }
      }
    }
    if (cooldown case final c?) out.add(Segment(c, 'Cool Down'));
    return out;
  }

  /// The time it will take, counting distance steps at [paceSecPerKm].
  Duration estimate({int paceSecPerKm = 360}) {
    var seconds = 0;
    for (final s in segments) {
      seconds += switch (s.step.measure) {
        StepMeasure.time => s.step.value,
        StepMeasure.distance => (s.step.value / 1000 * paceSecPerKm).round(),
      };
    }
    return Duration(seconds: seconds);
  }

  /// "Warm-up 10 min · 8 × 400 m · Cool-down 5 min"
  String get describe => [
    if (warmup case final w?) 'Warm-up ${w.describe}',
    for (final b in blocks) b.describe,
    if (cooldown case final c?) 'Cool-down ${c.describe}',
  ].join(' · ');

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'warmup': warmup?.toJson(),
    'blocks': [for (final b in blocks) b.toJson()],
    'cooldown': cooldown?.toJson(),
  };

  static CustomWorkout fromJson(Map<String, Object?> json) => CustomWorkout(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    type: WorkoutType.byName(json['type'] as String) ?? WorkoutType.other,
    warmup: json['warmup'] == null
        ? null
        : IntervalStep.fromJson((json['warmup'] as Map).cast()),
    blocks: [
      for (final b in json['blocks'] as List)
        IntervalBlock.fromJson((b as Map).cast()),
    ],
    cooldown: json['cooldown'] == null
        ? null
        : IntervalStep.fromJson((json['cooldown'] as Map).cast()),
  );

  /// A first workout to start from: the classic 8 × 400 m for a run, or
  /// 30 seconds on, 30 off for anything else.
  static CustomWorkout starter(WorkoutType type, {required int id}) {
    final distance = type.hasDistance;
    return CustomWorkout(
      id: id,
      name: distance ? '8 × 400 m' : '30/30 Intervals',
      type: type,
      warmup: const IntervalStep(StepKind.warmup, StepMeasure.time, 600),
      blocks: [
        IntervalBlock(
          repeats: 8,
          work: distance
              ? const IntervalStep(StepKind.work, StepMeasure.distance, 400)
              : const IntervalStep(StepKind.work, StepMeasure.time, 30),
          recover: IntervalStep(
            StepKind.recover,
            StepMeasure.time,
            distance ? 120 : 30,
          ),
        ),
      ],
      cooldown: const IntervalStep(StepKind.cooldown, StepMeasure.time, 300),
    );
  }
}

/// One step of a workout as it is run, with its name: "Work 3 of 8".
class Segment {
  const Segment(this.step, this.label);

  final IntervalStep step;
  final String label;
}

/// Follows a custom workout through its segments as the clock and the
/// distance move on.
///
/// Each segment starts where the last one ended, in moving time and in
/// distance; it ends when its own time, or its own distance, has passed.
/// [update] can cross more than one segment at once, after a long time in
/// the background.
class IntervalTracker {
  IntervalTracker(this.workout) : segments = workout.segments;

  final CustomWorkout workout;
  final List<Segment> segments;

  int _index = 0;
  Duration _startTime = Duration.zero;
  double _startKm = 0;
  Duration _time = Duration.zero;
  double _km = 0;

  /// The segment under way; [segments.length] once all are done.
  int get index => _index;

  bool get done => _index >= segments.length;

  Segment? get current => done ? null : segments[_index];
  Segment? get next =>
      _index + 1 < segments.length ? segments[_index + 1] : null;

  /// How far into the current segment, 0 to 1.
  double get progress {
    final segment = current;
    if (segment == null) return 1;
    final step = segment.step;
    return switch (step.measure) {
      StepMeasure.time =>
        (_time - _startTime).inMilliseconds / (step.value * 1000),
      StepMeasure.distance => (_km - _startKm) * 1000 / step.value,
    }.clamp(0.0, 1.0);
  }

  /// Seconds left in a time step.
  Duration? get timeLeft {
    final step = current?.step;
    if (step == null || step.measure != StepMeasure.time) return null;
    final left = Duration(seconds: step.value) - (_time - _startTime);
    return left.isNegative ? Duration.zero : left;
  }

  /// Metres left in a distance step.
  int? get metresLeft {
    final step = current?.step;
    if (step == null || step.measure != StepMeasure.distance) return null;
    final left = step.value - ((_km - _startKm) * 1000).round();
    return left < 0 ? 0 : left;
  }

  /// Moves on with the workout's moving time and distance. Returns whether
  /// a new segment started.
  bool update(Duration elapsed, double km) {
    _time = elapsed;
    _km = km;
    var moved = false;
    while (!done) {
      final step = segments[_index].step;
      final finished = switch (step.measure) {
        StepMeasure.time =>
          (elapsed - _startTime).inMilliseconds >= step.value * 1000,
        // Half a metre's grace: kilometres in floating point add up to
        // 399.9999 m as often as 400.
        StepMeasure.distance => (km - _startKm) * 1000 >= step.value - 0.5,
      };
      if (!finished) break;
      // The next one starts exactly where this one should have ended, as
      // far as can be told: by time for a time step, by distance for a
      // distance step.
      switch (step.measure) {
        case StepMeasure.time:
          _startTime += Duration(seconds: step.value);
          _startKm = km;
        case StepMeasure.distance:
          _startKm += step.value / 1000;
          _startTime = elapsed;
      }
      _index++;
      moved = true;
    }
    return moved;
  }

  /// Ends the segment under way now, as a lap button would.
  void skip() {
    if (done) return;
    _startTime = _time;
    _startKm = _km;
    _index++;
  }
}
