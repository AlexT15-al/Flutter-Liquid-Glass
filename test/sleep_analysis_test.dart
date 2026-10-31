import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/sleep.dart';

import 'support/sleep_nights.dart';

/// A night on the mattress: twenty restless minutes settling in, seven
/// hours of sleep with the odd turn, then a quarter of an hour awake.
List<int> night({int seed = 7}) => sleepCounts(seed: seed);

void main() {
  test('sleep begins after settling and ends before getting up', () {
    final stages = SleepAnalysis.hypnogram(night());
    final n = SleepNight(
      source: SleepSource.tracked,
      inBed: DateTime(2026, 10, 30, 23),
      outOfBed: DateTime(2026, 10, 30, 23).add(const Duration(minutes: 455)),
      hypnogram: stages,
    );
    final onset = n.fellAsleep!.difference(n.inBed).inMinutes;
    // Settling in, then the few still minutes that are usually still awake.
    expect(onset, inInclusiveRange(20, 30));
    final end = n.wokeUp!.difference(n.inBed).inMinutes;
    expect(end, inInclusiveRange(436, 441));
    expect(n.asleep.inMinutes, greaterThan(380));
    expect(n.efficiency, greaterThan(0.80));
  });

  test('stages fall in plausible shares, deep early and REM late', () {
    final stages = SleepAnalysis.hypnogram(night());
    final n = SleepNight(
      source: SleepSource.tracked,
      inBed: DateTime(2026, 10, 30, 23),
      outOfBed: DateTime(2026, 10, 31, 6, 35),
      hypnogram: stages,
    );
    final asleep = n.asleep.inMinutes;
    final deep = n.stageMinutes[SleepStage.deep]! / asleep;
    final rem = n.stageMinutes[SleepStage.rem]! / asleep;
    final light = n.stageMinutes[SleepStage.light]! / asleep;
    expect(deep, inInclusiveRange(0.10, 0.30));
    expect(rem, inInclusiveRange(0.12, 0.30));
    expect(light, greaterThan(0.40));

    final firstDeep = stages.indexOf(SleepStage.deep);
    final lastDeep = stages.lastIndexOf(SleepStage.deep);
    final lastRem = stages.lastIndexOf(SleepStage.rem);
    expect(firstDeep, lessThan(80));
    expect(lastDeep, lessThan(lastRem));
  });

  test('a restless night with no still stretch has no sleep', () {
    final stages = SleepAnalysis.hypnogram(List.filled(120, 12));
    expect(stages.every((s) => s == SleepStage.awake), isTrue);
  });

  test('the hypnogram survives being stored as letters', () {
    final stages = SleepAnalysis.hypnogram(night());
    final n = SleepNight(
      source: SleepSource.tracked,
      inBed: DateTime(2026, 10, 30, 23),
      outOfBed: DateTime(2026, 10, 31, 6, 35),
      hypnogram: stages,
    );
    expect(SleepNight.parseHypnogram(n.hypnogramCode), stages);
  });

  test('a full, steady night on schedule scores well; a short one does not', () {
    const schedule = SleepSchedule(
      bedtimeMinutes: 23 * 60,
      wakeMinutes: 6 * 60 + 30,
    );
    final good = SleepNight(
      source: SleepSource.tracked,
      inBed: DateTime(2026, 10, 30, 23),
      outOfBed: DateTime(2026, 10, 31, 6, 35),
      hypnogram: SleepAnalysis.hypnogram(night()),
    );
    final short = SleepNight(
      source: SleepSource.manual,
      inBed: DateTime(2026, 10, 31, 2, 30),
      outOfBed: DateTime(2026, 10, 31, 6, 30),
    );
    final goodScore = SleepScore.of(good, schedule);
    // ignore: avoid_print
    print(
      'score ${goodScore.value} d${goodScore.duration} e${goodScore.efficiency} c${goodScore.continuity} t${goodScore.timing} awakenings ${good.awakenings} waso ${good.awakeDuringSleep.inMinutes} asleep ${good.asleep.inMinutes}',
    );
    final shortScore = SleepScore.of(short, schedule);
    expect(goodScore.value, greaterThanOrEqualTo(80));
    expect(shortScore.value, lessThan(55));
    expect(shortScore.efficiency, isNull);
  });

  test('the schedule goal wraps past midnight', () {
    expect(
      const SleepSchedule(
        bedtimeMinutes: 23 * 60 + 30,
        wakeMinutes: 7 * 60,
      ).goal,
      const Duration(hours: 7, minutes: 30),
    );
  });
}
