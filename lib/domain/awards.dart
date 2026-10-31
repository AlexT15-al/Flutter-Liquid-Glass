/// What the awards are counted from.
class AwardStats {
  const AwardStats({
    this.workouts = 0,
    this.longestDistanceKm = 0,
    this.totalDistanceKm = 0,
    this.bestStepsDay = 0,
    this.nightsTracked = 0,
    this.longestRestedStreak = 0,
    this.hydratedDays = 0,
    this.foodDays = 0,
    this.trainingSessions = 0,
  });

  final int workouts;
  final double longestDistanceKm;
  final double totalDistanceKm;
  final int bestStepsDay;
  final int nightsTracked;

  /// Nights in a row with at least seven hours asleep.
  final int longestRestedStreak;

  /// Days with at least two litres of water.
  final int hydratedDays;

  /// Days with something eaten logged.
  final int foodDays;
  final int trainingSessions;
}

/// What an award is about, for its colour and glyph.
enum AwardKind { workout, distance, steps, sleep, nutrition, training }

/// One award: what it takes, and how far along it is.
class Award {
  const Award({
    required this.title,
    required this.detail,
    required this.kind,
    required this.current,
    required this.target,
    this.unit = '',
  });

  final String title;
  final String detail;
  final AwardKind kind;
  final double current;
  final double target;
  final String unit;

  bool get earned => current >= target;
  double get progress => (current / target).clamp(0.0, 1.0);

  /// Every award, in the order they are shown.
  static List<Award> all(AwardStats s) => [
    Award(
      title: 'First Workout',
      detail: 'Record your first workout.',
      kind: AwardKind.workout,
      current: s.workouts.toDouble(),
      target: 1,
    ),
    Award(
      title: '10 Workouts',
      detail: 'Record ten workouts.',
      kind: AwardKind.workout,
      current: s.workouts.toDouble(),
      target: 10,
    ),
    Award(
      title: '50 Workouts',
      detail: 'Record fifty workouts.',
      kind: AwardKind.workout,
      current: s.workouts.toDouble(),
      target: 50,
    ),
    Award(
      title: '5K',
      detail: 'Go five kilometres in one workout.',
      kind: AwardKind.distance,
      current: s.longestDistanceKm,
      target: 5,
      unit: 'km',
    ),
    Award(
      title: '10K',
      detail: 'Go ten kilometres in one workout.',
      kind: AwardKind.distance,
      current: s.longestDistanceKm,
      target: 10,
      unit: 'km',
    ),
    Award(
      title: 'A Marathon, Altogether',
      detail: 'Go 42.2 kilometres across all your workouts.',
      kind: AwardKind.distance,
      current: s.totalDistanceKm,
      target: 42.2,
      unit: 'km',
    ),
    Award(
      title: '10,000 Steps',
      detail: 'Walk ten thousand steps in a day.',
      kind: AwardKind.steps,
      current: s.bestStepsDay.toDouble(),
      target: 10000,
    ),
    Award(
      title: '20,000 Steps',
      detail: 'Walk twenty thousand steps in a day.',
      kind: AwardKind.steps,
      current: s.bestStepsDay.toDouble(),
      target: 20000,
    ),
    Award(
      title: 'First Night',
      detail: 'Record a night’s sleep.',
      kind: AwardKind.sleep,
      current: s.nightsTracked.toDouble(),
      target: 1,
    ),
    Award(
      title: 'Well Rested',
      detail: 'Sleep seven hours or more, seven nights in a row.',
      kind: AwardKind.sleep,
      current: s.longestRestedStreak.toDouble(),
      target: 7,
      unit: 'nights',
    ),
    Award(
      title: 'Hydrated',
      detail: 'Drink two litres of water on seven days.',
      kind: AwardKind.nutrition,
      current: s.hydratedDays.toDouble(),
      target: 7,
      unit: 'days',
    ),
    Award(
      title: 'Food Diary',
      detail: 'Log what you eat on seven days.',
      kind: AwardKind.nutrition,
      current: s.foodDays.toDouble(),
      target: 7,
      unit: 'days',
    ),
    Award(
      title: 'First Session',
      detail: 'Finish a session from your training plan.',
      kind: AwardKind.training,
      current: s.trainingSessions.toDouble(),
      target: 1,
    ),
    Award(
      title: '12 Sessions',
      detail: 'Finish twelve sessions from your training plan.',
      kind: AwardKind.training,
      current: s.trainingSessions.toDouble(),
      target: 12,
    ),
  ];
}
