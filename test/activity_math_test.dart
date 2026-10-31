import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/activity/activity_math.dart';
import 'package:halo/domain/activity_summary.dart';
import 'package:halo/domain/body_profile.dart';

void main() {
  const profile = BodyProfile(heightCm: 180, weightKg: 80);
  final day = DateTime(2026, 10, 31);

  StepSpan span(int startHour, int startMin, int minutes, int steps) {
    final start = DateTime(2026, 10, 31, startHour, startMin);
    return StepSpan(
      start: start,
      end: start.add(Duration(minutes: minutes)),
      steps: steps,
    );
  }

  test('an empty day is all zeros', () {
    final s = ActivityMath.summarize(spans: [], day: day, profile: profile);
    expect(s.steps, 0);
    expect(s.activeKcal, 0);
    expect(s.hourlySteps, hasLength(24));
  });

  test('brisk walking counts as exercise, slow walking does not', () {
    final s = ActivityMath.summarize(
      spans: [
        span(8, 0, 10, 1100), // 110 steps/min
        span(9, 0, 10, 600), // 60 steps/min
      ],
      day: day,
      profile: profile,
    );
    expect(s.steps, 1700);
    expect(s.exerciseMinutes, closeTo(10, 0.001));
  });

  test('distance and energy follow stride and weight', () {
    final s = ActivityMath.summarize(
      spans: [span(8, 0, 10, 1000)],
      day: day,
      profile: profile,
    );
    const km = 1000 * 1.8 * 0.414 / 1000;
    expect(s.distanceKm, closeTo(km, 1e-9));
    expect(s.activeKcal, closeTo(km * 80 * 0.5, 1e-9));
  });

  test('a span across midnight is split by time', () {
    final s = ActivityMath.summarize(
      spans: [
        StepSpan(
          start: DateTime(2026, 10, 30, 23, 30),
          end: DateTime(2026, 10, 31, 0, 30),
          steps: 600,
        ),
      ],
      day: day,
      profile: profile,
    );
    expect(s.steps, 300);
    expect(s.hourlySteps[0], 300);
  });

  test('an hour with 250 steps or more is an active hour', () {
    final s = ActivityMath.summarize(
      spans: [
        span(7, 0, 30, 300),
        span(12, 0, 30, 200),
        span(18, 10, 20, 250),
      ],
      day: day,
      profile: profile,
    );
    expect(s.activeHours, 2);
  });

  test('a long gap spreads its steps over the hours it covers', () {
    final s = ActivityMath.summarize(
      spans: [span(10, 0, 120, 1200)],
      day: day,
      profile: profile,
    );
    expect(s.hourlySteps[10], 600);
    expect(s.hourlySteps[11], 600);
    // 10 steps a minute is not brisk, whatever the total.
    expect(s.exerciseMinutes, 0);
  });

  test('an instantaneous span counts only on its own day', () {
    final at = DateTime(2026, 10, 30, 22);
    final s = ActivityMath.summarize(
      spans: [StepSpan(start: at, end: at, steps: 40)],
      day: day,
      profile: profile,
    );
    expect(s.steps, 0);
  });

  test('hourly energy and exercise add up to the day totals', () {
    final s = ActivityMath.summarize(
      spans: [span(8, 40, 40, 4400), span(14, 0, 30, 900)],
      day: day,
      profile: profile,
    );
    final kcal = s.hourlyKcal.fold<double>(0, (a, b) => a + b);
    final minutes = s.hourlyExerciseMinutes.fold<double>(0, (a, b) => a + b);
    expect(kcal, closeTo(s.activeKcal, 1e-6));
    expect(minutes, closeTo(s.exerciseMinutes, 1e-6));
    expect(s.hourlyExerciseMinutes[8], closeTo(20, 1e-6));
    expect(s.hourlyExerciseMinutes[9], closeTo(20, 1e-6));
    expect(s.hourlyExerciseMinutes[14], 0);
  });
}
