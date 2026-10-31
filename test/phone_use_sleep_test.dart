import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/phone_use.dart';
import 'package:halo/domain/sleep.dart';

ScreenEvent on(DateTime t) => ScreenEvent(t, ScreenEventType.screenOn);
ScreenEvent off(DateTime t) => ScreenEvent(t, ScreenEventType.screenOff);
ScreenEvent unlock(DateTime t) => ScreenEvent(t, ScreenEventType.unlock);

/// Picked up and used for [minutes], unlocking it.
List<ScreenEvent> use(DateTime t, int minutes) => [
  on(t),
  unlock(t.add(const Duration(seconds: 2))),
  off(t.add(Duration(minutes: minutes))),
];

void main() {
  final evening = DateTime(2026, 10, 30, 22);
  final now = DateTime(2026, 10, 31, 9, 30);

  test('from the last use at night to the first unlock in the morning', () {
    final events = [
      ...use(evening, 20),
      ...use(DateTime(2026, 10, 30, 23, 40), 15), // last look: ends 23:55
      ...use(DateTime(2026, 10, 31, 7, 5), 10), // morning
      ...use(DateTime(2026, 10, 31, 9, 20), 5),
    ];
    final e = PhoneUseSleep.estimate(events, now)!;
    expect(e.start, DateTime(2026, 10, 30, 23, 55));
    expect(e.end, DateTime(2026, 10, 31, 7, 5, 2));
    expect(e.awake, isEmpty);
  });

  test('a glance at the time without unlocking does not wake you', () {
    final events = [
      ...use(DateTime(2026, 10, 30, 23), 30),
      on(DateTime(2026, 10, 31, 3, 12)),
      off(DateTime(2026, 10, 31, 3, 12, 8)),
      ...use(DateTime(2026, 10, 31, 6, 50), 10),
    ];
    final e = PhoneUseSleep.estimate(events, now)!;
    expect(e.start, DateTime(2026, 10, 30, 23, 30));
    expect(e.end.hour, 6);
  });

  test('a brief use in the night is minutes awake, not the morning', () {
    final events = [
      ...use(DateTime(2026, 10, 30, 23), 30),
      ...use(DateTime(2026, 10, 31, 3, 0), 3),
      ...use(DateTime(2026, 10, 31, 7, 0), 10),
    ];
    final e = PhoneUseSleep.estimate(events, now)!;
    expect(e.start, DateTime(2026, 10, 30, 23, 30));
    expect(e.end.hour, 7);
    expect(e.awake, hasLength(1));
    final night = e.toNight();
    expect(night.source, SleepSource.phone);
    expect(night.staged, isFalse);
    expect(night.stageMinutes[SleepStage.awake], inInclusiveRange(3, 4));
    expect(night.asleep.inMinutes, closeTo(7 * 60 + 30 - 3, 2));
  });

  test('a long use in the night splits it, and the longer part counts', () {
    final events = [
      ...use(DateTime(2026, 10, 30, 23), 30), // to 23:30
      ...use(DateTime(2026, 10, 31, 1, 0), 40), // up for 40 min
      ...use(DateTime(2026, 10, 31, 7, 30), 10),
    ];
    final e = PhoneUseSleep.estimate(events, now)!;
    expect(e.start, DateTime(2026, 10, 31, 1, 40));
    expect(e.end.hour, 7);
  });

  test('editing the times keeps the awake minutes inside them', () {
    final events = [
      ...use(DateTime(2026, 10, 31, 2, 50), 10), // to 03:00
      ...use(DateTime(2026, 10, 31, 4, 0), 2),
      ...use(DateTime(2026, 10, 31, 6, 30), 5),
    ];
    final e = PhoneUseSleep.estimate(events, now)!;
    expect(e.start, DateTime(2026, 10, 31, 3));
    // Measured 03:00–06:30; the user says it was really until 09:00.
    final night = e.toNight(to: DateTime(2026, 10, 31, 9));
    expect(night.timeInBed, const Duration(hours: 6));
    expect(night.stageMinutes[SleepStage.awake], inInclusiveRange(2, 3));
  });

  test('no night before the phone is picked up, and none too short', () {
    expect(PhoneUseSleep.estimate(use(evening, 30), now), isNull);
    final short = [
      ...use(DateTime(2026, 10, 31, 1), 10),
      ...use(DateTime(2026, 10, 31, 3), 10),
      ...use(DateTime(2026, 10, 31, 5), 10),
    ];
    expect(PhoneUseSleep.estimate(short, now), isNull);
  });
}
