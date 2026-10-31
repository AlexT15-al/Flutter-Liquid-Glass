/// The daily targets the rings and the step tile fill towards.
class ActivityGoals {
  const ActivityGoals({
    this.moveKcal = 400,
    this.exerciseMinutes = 30,
    this.activeHours = 10,
    this.steps = 10000,
  });

  /// Active energy, in kilocalories. 400 is a moderate starting goal for
  /// someone whose only tracker is the phone in their pocket.
  final int moveKcal;

  /// Minutes of brisk movement. 30 is the WHO's daily guideline.
  final int exerciseMinutes;

  /// Hours with at least some walking in them. Fewer than Apple's twelve
  /// stand hours: a phone on a desk counts nothing, where a watch on a wrist
  /// would, so twelve would be out of reach on an ordinary day.
  final int activeHours;

  final int steps;

  static const fallback = ActivityGoals();

  ActivityGoals copyWith({
    int? moveKcal,
    int? exerciseMinutes,
    int? activeHours,
    int? steps,
  }) =>
      ActivityGoals(
        moveKcal: moveKcal ?? this.moveKcal,
        exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
        activeHours: activeHours ?? this.activeHours,
        steps: steps ?? this.steps,
      );

  Map<String, Object?> toJson() => {
        'moveKcal': moveKcal,
        'exerciseMinutes': exerciseMinutes,
        'activeHours': activeHours,
        'steps': steps,
      };

  factory ActivityGoals.fromJson(Map<String, Object?> json) => ActivityGoals(
        moveKcal: (json['moveKcal'] as num?)?.toInt() ?? fallback.moveKcal,
        exerciseMinutes: (json['exerciseMinutes'] as num?)?.toInt() ??
            fallback.exerciseMinutes,
        activeHours:
            (json['activeHours'] as num?)?.toInt() ?? fallback.activeHours,
        steps: (json['steps'] as num?)?.toInt() ?? fallback.steps,
      );
}
