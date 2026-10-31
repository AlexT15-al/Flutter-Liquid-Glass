import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/activity/activity_history.dart';
import 'package:halo/domain/activity_summary.dart';
import 'package:halo/domain/body_profile.dart';
import 'package:halo/domain/trends.dart';

void main() {
  test('each day is summarised from its own steps, midnight shared', () {
    final start = DateTime(2026, 10, 1);
    final days = ActivityHistory.summarize(
      [
        StepSpan(
          start: DateTime(2026, 10, 1, 9),
          end: DateTime(2026, 10, 1, 10),
          steps: 3000,
        ),
        StepSpan(
          start: DateTime(2026, 10, 3, 18),
          end: DateTime(2026, 10, 3, 19),
          steps: 5000,
        ),
        // Half an hour either side of midnight.
        StepSpan(
          start: DateTime(2026, 10, 3, 23, 30),
          end: DateTime(2026, 10, 4, 0, 30),
          steps: 600,
        ),
      ],
      const [],
      start,
      DateTime(2026, 10, 5),
      BodyProfile.fallback,
    );
    expect(days.map((d) => d.day.day), [1, 2, 3, 4]);
    expect(days[0].steps, 3000);
    expect(days[1].steps, 0);
    expect(days[2].steps, 5300);
    expect(days[3].steps, 300);
  });

  test('trends compare 90 days with the year, steady within 3%', () {
    expect(
      const Trend(title: 'Move', unit: '', recent: 450, year: 400).direction,
      TrendDirection.up,
    );
    expect(
      const Trend(title: 'Move', unit: '', recent: 405, year: 400).direction,
      TrendDirection.steady,
    );
    const weight = Trend(
      title: 'Weight',
      unit: '',
      recent: 78,
      year: 82,
      higherIsBetter: false,
    );
    expect(weight.direction, TrendDirection.down);
    expect(weight.good, isTrue);
    expect(Trend.average([0, 10, 20]), 15);
  });
}
