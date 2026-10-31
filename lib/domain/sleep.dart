import 'dart:math' as math;

/// A stage of sleep, as estimated from movement.
///
/// Light is Samsung's word for what Apple calls Core: the plain, most common
/// stage between the two others.
enum SleepStage {
  awake('A', 'Awake'),
  rem('R', 'REM'),
  light('L', 'Light'),
  deep('D', 'Deep'),

  /// Asleep, stage unknown: a night measured from when the phone was last
  /// and first used, which says when sleep was but not how deep.
  asleep('S', 'Asleep');

  const SleepStage(this.code, this.title);

  /// One letter per minute in a stored hypnogram.
  final String code;
  final String title;

  static SleepStage? fromCode(String code) => switch (code) {
    'A' => awake,
    'R' => rem,
    'L' => light,
    'D' => deep,
    'S' => asleep,
    _ => null,
  };
}

/// How a night was recorded.
enum SleepSource {
  /// The phone lay on the mattress and felt the night through its
  /// accelerometer.
  tracked,

  /// Entered by hand: times only, no stages.
  manual,

  /// Worked out from the phone's screen: the last use at night and the first
  /// unlock in the morning, as Samsung Health does. Asleep or awake, no
  /// stages.
  phone;

  static SleepSource byName(String name) =>
      SleepSource.values.asNameMap()[name] ?? SleepSource.manual;
}

/// One night: in bed to out of bed, and, for a tracked one, a stage for every
/// minute in between.
class SleepNight {
  SleepNight({
    this.id,
    required this.source,
    required this.inBed,
    required this.outOfBed,
    this.hypnogram = const [],
  });

  final int? id;
  final SleepSource source;
  final DateTime inBed;
  final DateTime outOfBed;

  /// A stage per minute from [inBed]. Empty for a night entered by hand.
  final List<SleepStage> hypnogram;

  /// A minute-by-minute record, awake or asleep: tracked or from the phone.
  bool get hasStages => hypnogram.isNotEmpty;

  /// Sleep split into REM, light and deep: only a night on the mattress.
  bool get staged => hypnogram.any(
    (s) => s == SleepStage.rem || s == SleepStage.light || s == SleepStage.deep,
  );

  Duration get timeInBed => outOfBed.difference(inBed);

  /// The minute sleep began, if it did.
  late final int? _onset = () {
    final i = hypnogram.indexWhere((s) => s != SleepStage.awake);
    return i < 0 ? null : i;
  }();

  late final int? _final = () {
    final i = hypnogram.lastIndexWhere((s) => s != SleepStage.awake);
    return i < 0 ? null : i + 1;
  }();

  /// When sleep began: the first minute asleep.
  DateTime? get fellAsleep {
    if (!hasStages) return inBed;
    final onset = _onset;
    return onset == null ? null : inBed.add(Duration(minutes: onset));
  }

  /// When sleep ended: just after the last minute asleep.
  DateTime? get wokeUp {
    if (!hasStages) return outOfBed;
    final end = _final;
    return end == null ? null : inBed.add(Duration(minutes: end));
  }

  /// Minutes in each stage between falling asleep and waking up.
  late final Map<SleepStage, int> stageMinutes = () {
    final totals = {for (final s in SleepStage.values) s: 0};
    final onset = _onset;
    final end = _final;
    if (onset == null || end == null) return totals;
    for (var i = onset; i < end; i++) {
      totals[hypnogram[i]] = totals[hypnogram[i]]! + 1;
    }
    return totals;
  }();

  /// Time actually asleep: the night less every minute awake in it.
  Duration get asleep {
    if (!hasStages) return timeInBed;
    final m = stageMinutes;
    return Duration(
      minutes:
          m[SleepStage.rem]! +
          m[SleepStage.light]! +
          m[SleepStage.deep]! +
          m[SleepStage.asleep]!,
    );
  }

  /// Awake after first falling asleep (WASO).
  Duration get awakeDuringSleep =>
      Duration(minutes: stageMinutes[SleepStage.awake]!);

  /// Asleep as a share of the time in bed.
  double? get efficiency {
    if (!hasStages || timeInBed.inMinutes <= 0) return null;
    return asleep.inMinutes / timeInBed.inMinutes;
  }

  /// Times the night broke: runs of at least three minutes awake between
  /// falling asleep and waking up. Shorter ones are the turns and stirs every
  /// night has, a dozen or more of them, and nobody remembers.
  late final int awakenings = () {
    final onset = _onset;
    final end = _final;
    if (onset == null || end == null) return 0;
    var count = 0;
    var run = 0;
    for (var i = onset; i < end; i++) {
      if (hypnogram[i] == SleepStage.awake) {
        run++;
      } else {
        if (run >= 3) count++;
        run = 0;
      }
    }
    return count;
  }();

  /// The night a session belongs to: the date it ended on, so a night that
  /// starts before midnight and one that starts after both count for the
  /// morning they end in.
  DateTime get morning => DateTime(outOfBed.year, outOfBed.month, outOfBed.day);

  String get hypnogramCode => hypnogram.map((s) => s.code).join();

  static List<SleepStage> parseHypnogram(String code) => [
    for (final c in code.split('')) ?SleepStage.fromCode(c),
  ];
}

/// When the user means to sleep: a bedtime and a wake-up time, every night.
class SleepSchedule {
  const SleepSchedule({
    this.bedtimeMinutes = 23 * 60,
    this.wakeMinutes = 7 * 60,
  });

  /// Minutes after midnight.
  final int bedtimeMinutes;
  final int wakeMinutes;

  /// The sleep the schedule allows for.
  Duration get goal {
    final minutes = (wakeMinutes - bedtimeMinutes) % (24 * 60);
    return Duration(minutes: minutes == 0 ? 24 * 60 : minutes);
  }

  SleepSchedule copyWith({int? bedtimeMinutes, int? wakeMinutes}) =>
      SleepSchedule(
        bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
        wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      );

  Map<String, Object> toJson() => {
    'bedtime': bedtimeMinutes,
    'wake': wakeMinutes,
  };

  static SleepSchedule fromJson(Map<String, Object?> json) => SleepSchedule(
    bedtimeMinutes: (json['bedtime'] as num?)?.toInt() ?? 23 * 60,
    wakeMinutes: (json['wake'] as num?)?.toInt() ?? 7 * 60,
  );
}

/// From movement to sleep: which minutes were asleep, and in which stage.
///
/// The phone lies on the mattress and counts, minute by minute, how often it
/// felt the bed move. That is actigraphy, the method sleep labs use with a
/// wrist device, done through the mattress:
///
/// 1. Each minute is scored asleep or awake from a weighted window of the
///    minutes around it (Cole–Kripke), so one restless minute in a still
///    stretch stays asleep and a still minute in a restless stretch does not.
/// 2. Webster's rescoring rules then tidy the edges: the first minutes of
///    stillness after a long time awake are usually still awake.
/// 3. Sleep begins with the first ten minutes asleep in a row.
///
/// Stages cannot be measured without brain waves; they are estimated from
/// the shape of a typical night (cycles of about ninety minutes, deep sleep
/// early in each and early in the night, REM late in each and later in the
/// night) and from movement, which rules deep sleep out. The app always says
/// so.
abstract final class SleepAnalysis {
  /// Cole–Kripke weights for the minutes from four before to two after.
  static const _weights = [106, 54, 58, 76, 230, 74, 67];
  static const double _scale = 0.0007;

  /// The length of a typical sleep cycle.
  static const int cycleMinutes = 90;

  static List<SleepStage> hypnogram(List<int> counts) {
    if (counts.isEmpty) return const [];
    final wake = _rescore(_wakeMinutes(counts));
    final n = counts.length;

    // Sleep begins with ten minutes asleep in a row, and ends after the last
    // stretch of at least five.
    final onset = _firstRun(wake, asleep: true, length: 10);
    if (onset == null) return List.filled(n, SleepStage.awake);
    var end = n;
    while (end > onset && wake[end - 1]) {
      end--;
    }

    final stages = List.filled(n, SleepStage.awake);
    for (var i = onset; i < end; i++) {
      if (wake[i]) continue;
      final since = i - onset;
      final cycle = since ~/ cycleMinutes;
      final p = (since % cycleMinutes) / cycleMinutes;
      final still = _still(counts, i);

      // Deep: still, in the first part of one of the first cycles, and less
      // of each cycle as the night goes on.
      final deepEnd = 0.55 - 0.12 * cycle;
      // REM: the end of each cycle, longer later; brief in the first.
      final remStart = cycle == 0 ? 0.86 : math.max(0.55, 0.78 - 0.06 * cycle);

      if (still && cycle < 4 && p >= 0.12 && p < deepEnd) {
        stages[i] = SleepStage.deep;
      } else if (p >= remStart && counts[i] <= 3) {
        stages[i] = SleepStage.rem;
      } else {
        stages[i] = SleepStage.light;
      }
    }
    _smooth(stages, onset, end);
    return stages;
  }

  /// What a person would recognise as their night: a stir of a minute or two
  /// in the middle of sleep (turning over) is not waking up, and a stage that
  /// lasts under three minutes is part of the one around it.
  static void _smooth(List<SleepStage> stages, int onset, int end) {
    List<(SleepStage, int, int)> runs() {
      final out = <(SleepStage, int, int)>[];
      var start = onset;
      for (var i = onset + 1; i <= end; i++) {
        if (i == end || stages[i] != stages[start]) {
          out.add((stages[start], start, i));
          start = i;
        }
      }
      return out;
    }

    for (final (stage, from, to) in runs()) {
      if (stage == SleepStage.awake && to - from <= 2) {
        for (var i = from; i < to; i++) {
          stages[i] = SleepStage.light;
        }
      }
    }
    final merged = runs();
    for (var r = 0; r < merged.length; r++) {
      final (stage, from, to) = merged[r];
      if (stage == SleepStage.awake || to - from >= 3) continue;
      final previous = from > onset ? stages[from - 1] : null;
      final into = previous != null && previous != SleepStage.awake
          ? previous
          : (to < end ? stages[to] : SleepStage.light);
      for (var i = from; i < to; i++) {
        stages[i] = into == SleepStage.awake ? SleepStage.light : into;
      }
    }
  }

  static List<bool> _wakeMinutes(List<int> counts) {
    final n = counts.length;
    return [
      for (var t = 0; t < n; t++)
        () {
          var sum = 0.0;
          for (var k = 0; k < _weights.length; k++) {
            final i = t + k - 4;
            if (i >= 0 && i < n) sum += _weights[k] * counts[i];
          }
          return sum * _scale >= 1;
        }(),
    ];
  }

  /// Webster's rules, from wake to sleep only.
  static List<bool> _rescore(List<bool> wake) {
    final out = [...wake];
    final n = out.length;
    var awakeRun = 0;
    var carry = 0;
    for (var i = 0; i < n; i++) {
      if (wake[i]) {
        awakeRun++;
        carry = awakeRun >= 15
            ? 4
            : awakeRun >= 10
            ? 3
            : awakeRun >= 4
            ? 1
            : 0;
      } else {
        awakeRun = 0;
        if (carry > 0) {
          out[i] = true;
          carry--;
        }
      }
    }
    // Six minutes or less asleep with ten awake either side was not sleep.
    var i = 0;
    while (i < n) {
      if (out[i]) {
        i++;
        continue;
      }
      var j = i;
      while (j < n && !out[j]) {
        j++;
      }
      if (j - i <= 6 &&
          _awakeFor(out, i - 1, -1) >= 10 &&
          _awakeFor(out, j, 1) >= 10) {
        for (var k = i; k < j; k++) {
          out[k] = true;
        }
      }
      i = j;
    }
    return out;
  }

  static int _awakeFor(List<bool> wake, int from, int step) {
    var count = 0;
    for (var i = from; i >= 0 && i < wake.length && wake[i]; i += step) {
      count++;
    }
    return count;
  }

  static int? _firstRun(
    List<bool> wake, {
    required bool asleep,
    required int length,
  }) {
    var run = 0;
    for (var i = 0; i < wake.length; i++) {
      if (wake[i] != asleep) {
        run++;
        if (run >= length) return i - length + 1;
      } else {
        run = 0;
      }
    }
    return null;
  }

  /// At most a single twitch in this minute and the two either side of it.
  static bool _still(List<int> counts, int i) {
    var sum = 0;
    for (var k = i - 2; k <= i + 2; k++) {
      if (k >= 0 && k < counts.length) sum += counts[k];
    }
    return sum <= 1;
  }
}

/// A night's score out of 100, and what it is made of.
class SleepScore {
  const SleepScore._({
    required this.value,
    required this.duration,
    required this.efficiency,
    required this.continuity,
    required this.timing,
  });

  final int value;

  /// Each part from 0 to 1. Efficiency and continuity are null for a night
  /// entered by hand, which has no minutes to judge them by.
  final double duration;
  final double? efficiency;
  final double? continuity;
  final double timing;

  String get label => switch (value) {
    >= 85 => 'Excellent',
    >= 70 => 'Good',
    >= 50 => 'Fair',
    _ => 'Poor',
  };

  /// Weighted: how long (50), how unbroken in bed (25), how few and short the
  /// awakenings (15), and how close to the planned bedtime (10). A night
  /// without stages is scored on the parts it has, weighted the same way.
  static SleepScore of(SleepNight night, SleepSchedule schedule) {
    final goal = schedule.goal.inMinutes;
    final asleep = night.asleep.inMinutes;
    final duration = goal <= 0 ? 1.0 : (asleep / goal).clamp(0.0, 1.0);

    final eff = night.efficiency;
    final efficiency = eff == null
        ? null
        // 90% or more asleep in bed is full marks; under 65% is none.
        : ((eff - 0.65) / (0.90 - 0.65)).clamp(0.0, 1.0);

    // A couple of awakenings are normal and cost nothing.
    final continuity = night.hasStages
        ? (1 -
                  math.max(0, night.awakenings - 2) / 10 * 0.5 -
                  night.awakeDuringSleep.inMinutes / 90 * 0.5)
              .clamp(0.0, 1.0)
        : null;

    final fellAsleep = night.fellAsleep ?? night.inBed;
    final minuteOfDay = fellAsleep.hour * 60 + fellAsleep.minute;
    var off = (minuteOfDay - schedule.bedtimeMinutes).abs() % (24 * 60);
    off = math.min(off, 24 * 60 - off);
    final timing = (1 - (off - 30) / 90).clamp(0.0, 1.0);

    var total = 50 * duration + 10 * timing;
    var weight = 60.0;
    if (efficiency != null) {
      total += 25 * efficiency;
      weight += 25;
    }
    if (continuity != null) {
      total += 15 * continuity;
      weight += 15;
    }
    return SleepScore._(
      value: (total / weight * 100).round(),
      duration: duration,
      efficiency: efficiency,
      continuity: continuity,
      timing: timing,
    );
  }
}
