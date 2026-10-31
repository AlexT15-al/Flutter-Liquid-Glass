import 'dart:math' as math;

import 'sleep.dart';

/// What the screen did, as Android's usage history records it.
enum ScreenEventType { screenOn, screenOff, unlock, lock }

class ScreenEvent {
  const ScreenEvent(this.time, this.type);

  final DateTime time;
  final ScreenEventType type;
}

/// A night worked out from the phone: when it was last put down and when it
/// was first picked up again, with any brief look at it in between.
class SleepEstimate {
  const SleepEstimate({
    required this.start,
    required this.end,
    this.awake = const [],
  });

  final DateTime start;
  final DateTime end;

  /// Times the phone was used in the night: awake for those minutes.
  final List<(DateTime, DateTime)> awake;

  Duration get length => end.difference(start);

  /// The morning it ends on, which names the night.
  DateTime get morning => DateTime(end.year, end.month, end.day);

  /// As a night, between [from] and [to] if the user moved the times: asleep
  /// every minute except the ones the phone was in use.
  SleepNight toNight({DateTime? from, DateTime? to}) {
    final start = from ?? this.start;
    final end = to ?? this.end;
    final minutes = math.max(0, end.difference(start).inMinutes);
    final stages = List.filled(minutes, SleepStage.asleep);
    for (final (a, b) in awake) {
      final first = math.max(0, a.difference(start).inMinutes);
      final last = math.min(
        minutes,
        (b.difference(start).inSeconds / 60).ceil(),
      );
      for (var i = first; i < last; i++) {
        stages[i] = SleepStage.awake;
      }
    }
    return SleepNight(
      source: SleepSource.phone,
      inBed: start,
      outOfBed: end,
      hypnogram: stages,
    );
  }
}

/// Sleep from the screen, the way Samsung Health measures it without a
/// watch: the longest stretch of the night the phone went unused.
///
/// The phone counts as in use from an unlock to the screen going off. Turning
/// the screen on without unlocking (a glance at the time or a notification)
/// does not count. A use of a few minutes in the middle of the night (an
/// alarm checked, a message read) does not end the night; it becomes a few
/// minutes awake inside it.
abstract final class PhoneUseSleep {
  /// Uses this short in the night are a wake-up, not the morning.
  static const brief = Duration(minutes: 5);

  /// Shorter stretches are naps or a phone left on a desk, not a night.
  static const minimum = Duration(hours: 3);

  /// The night that ended on the morning of [now]'s date, if there was one.
  ///
  /// Looked for from 18:00 the evening before up to [now] (at most 15:00, so
  /// an afternoon nap is not taken for the night).
  static SleepEstimate? estimate(List<ScreenEvent> events, DateTime now) {
    final morning = DateTime(now.year, now.month, now.day);
    final from = morning.subtract(const Duration(hours: 6));
    final cap = morning.add(const Duration(hours: 15));
    final to = now.isBefore(cap) ? now : cap;
    if (!to.isAfter(from)) return null;

    final sorted = [...events]..sort((a, b) => a.time.compareTo(b.time));
    // A phone without a lock screen never reports unlocking: there, the
    // screen coming on is the use.
    final locks = sorted.any((e) => e.type == ScreenEventType.unlock);

    final uses = <(DateTime, DateTime)>[];
    DateTime? since;
    // In use at the start of the window if the first thing seen is the
    // screen going off.
    final first = sorted.where((e) => !e.time.isBefore(from)).firstOrNull;
    if (first != null &&
        (first.type == ScreenEventType.screenOff ||
            first.type == ScreenEventType.lock)) {
      since = from;
    }
    for (final e in sorted) {
      if (e.time.isBefore(from) || e.time.isAfter(to)) continue;
      final begins = locks
          ? e.type == ScreenEventType.unlock
          : e.type == ScreenEventType.screenOn;
      final ends =
          e.type == ScreenEventType.screenOff || e.type == ScreenEventType.lock;
      if (begins && since == null) {
        since = e.time;
      } else if (ends && since != null) {
        uses.add((since, e.time));
        since = null;
      }
    }
    // Still in use now: that is this very moment, the app open.
    if (since != null) uses.add((since, to));

    // The quiet stretches between uses.
    final gaps = <(DateTime, DateTime)>[];
    var cursor = from;
    for (final (a, b) in uses) {
      if (a.isAfter(cursor)) gaps.add((cursor, a));
      if (b.isAfter(cursor)) cursor = b;
    }
    // No use since: the phone has not been picked up yet, so the night has
    // not ended.
    if (uses.isEmpty || !to.isAfter(cursor) && gaps.isEmpty) return null;

    // Join quiet stretches across brief uses; keep the longest night.
    SleepEstimate? best;
    var i = 0;
    while (i < gaps.length) {
      var start = gaps[i].$1;
      var end = gaps[i].$2;
      var quiet = end.difference(start);
      final awake = <(DateTime, DateTime)>[];
      var j = i + 1;
      while (j < gaps.length && gaps[j].$1.difference(end) <= brief) {
        awake.add((end, gaps[j].$1));
        end = gaps[j].$2;
        quiet += gaps[j].$2.difference(gaps[j].$1);
        j++;
      }
      // A stretch running from the very start of the window began before
      // it; it cannot be measured.
      final measurable = start.isAfter(from);
      if (measurable &&
          quiet >= minimum &&
          (best == null || quiet > best.length - _awakeOf(best))) {
        best = SleepEstimate(start: start, end: end, awake: awake);
      }
      i = j;
      start = end;
    }

    // A night is mostly at night: its middle falls between 21:00 and 11:00.
    if (best != null) {
      final middle = best.start.add(best.length ~/ 2);
      final hour = middle.hour + middle.minute / 60;
      if (hour > 11 && hour < 21) return null;
    }
    return best;
  }

  static Duration _awakeOf(SleepEstimate e) =>
      e.awake.fold(Duration.zero, (sum, a) => sum + a.$2.difference(a.$1));
}
