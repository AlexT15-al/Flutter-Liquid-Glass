import 'dart:convert';

import '../../domain/activity_goals.dart';
import '../../domain/app_theme_mode.dart';
import '../../domain/body_profile.dart';
import '../../domain/sleep.dart';
import '../../features/today/domain/today_card.dart';
import '../database/app_database.dart';

/// Typed access to the small settings in the key-value table.
///
/// Every read has a default, so a fresh install needs no setup step before
/// the first screen can draw. The watch methods are drift streams: a screen
/// that writes a value does nothing else, and everything showing it follows.
class HaloPreferences {
  HaloPreferences(this._db);

  final AppDatabase _db;

  static const _profileKey = 'profile';
  static const _goalsKey = 'activity_goals';
  static const _todayCardsKey = 'today_cards';
  static const _stepCounterKey = 'step_counter';
  static const _themeModeKey = 'theme_mode';
  static const _hapticsKey = 'haptics';
  static const _liveActivityKey = 'live_activity';
  static const _sleepScheduleKey = 'sleep_schedule';
  static const _sleepDismissedKey = 'sleep_dismissed';

  // ── Appearance ─────────────────────────────────────────────────────────────

  Stream<AppThemeMode> watchThemeMode() => _db
      .watchValue(_themeModeKey)
      .map(
        (raw) => AppThemeMode.values.asNameMap()[raw] ?? AppThemeMode.system,
      );

  Future<AppThemeMode> readThemeMode() async =>
      AppThemeMode.values.asNameMap()[await _db.readValue(_themeModeKey)] ??
      AppThemeMode.system;

  Future<void> setThemeMode(AppThemeMode mode) =>
      _db.writeValue(_themeModeKey, mode.name);

  // ── Feedback ───────────────────────────────────────────────────────────────

  /// Haptic feedback across the app. On unless turned off.
  Stream<bool> watchHaptics() => _watchFlag(_hapticsKey);
  Future<bool> readHaptics() => _readFlag(_hapticsKey);
  Future<void> setHaptics(bool on) => _db.writeValue(_hapticsKey, '$on');

  /// The workout in progress on the lock screen, the status bar and, on a
  /// Galaxy, the Now Bar. On unless turned off.
  Stream<bool> watchLiveActivity() => _watchFlag(_liveActivityKey);
  Future<bool> readLiveActivity() => _readFlag(_liveActivityKey);
  Future<void> setLiveActivity(bool on) =>
      _db.writeValue(_liveActivityKey, '$on');

  Stream<bool> _watchFlag(String key) =>
      _db.watchValue(key).map((raw) => raw != 'false').distinct();

  Future<bool> _readFlag(String key) async =>
      await _db.readValue(key) != 'false';

  // ── Sleep ──────────────────────────────────────────────────────────────────

  Stream<SleepSchedule> watchSleepSchedule() =>
      _db.watchValue(_sleepScheduleKey).map(_decodeSchedule);

  Future<SleepSchedule> readSleepSchedule() async =>
      _decodeSchedule(await _db.readValue(_sleepScheduleKey));

  Future<void> setSleepSchedule(SleepSchedule schedule) =>
      _db.writeValue(_sleepScheduleKey, jsonEncode(schedule.toJson()));

  /// The start of a detected night the user said was not sleep, so it is
  /// not offered again.
  Future<DateTime?> readDismissedSleep() async {
    final raw = await _db.readValue(_sleepDismissedKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setDismissedSleep(DateTime start) =>
      _db.writeValue(_sleepDismissedKey, start.toIso8601String());

  static SleepSchedule _decodeSchedule(String? raw) {
    if (raw == null) return const SleepSchedule();
    try {
      return SleepSchedule.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return const SleepSchedule();
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Stream<BodyProfile> watchProfile() => _db
      .watchValue(_profileKey)
      .map(
        (raw) => raw == null
            ? BodyProfile.fallback
            : BodyProfile.fromJson(_decode(raw)),
      );

  Future<void> setProfile(BodyProfile profile) =>
      _db.writeValue(_profileKey, jsonEncode(profile.toJson()));

  // ── Goals ──────────────────────────────────────────────────────────────────

  Stream<ActivityGoals> watchGoals() => _db
      .watchValue(_goalsKey)
      .map(
        (raw) => raw == null
            ? ActivityGoals.fallback
            : ActivityGoals.fromJson(_decode(raw)),
      );

  Future<void> setGoals(ActivityGoals goals) =>
      _db.writeValue(_goalsKey, jsonEncode(goals.toJson()));

  // ── Today layout ───────────────────────────────────────────────────────────

  /// The cards on Today, in order. Unknown names from a newer build are
  /// skipped rather than failing the whole list.
  Stream<List<TodayCard>> watchTodayCards() =>
      _db.watchValue(_todayCardsKey).map((raw) {
        if (raw == null) return TodayCard.defaults;
        final names = (jsonDecode(raw) as List<dynamic>).cast<String>();
        final byName = TodayCard.values.asNameMap();
        return [for (final name in names) ?byName[name]];
      });

  Future<void> setTodayCards(List<TodayCard> cards) => _db.writeValue(
    _todayCardsKey,
    jsonEncode([for (final card in cards) card.name]),
  );

  // ── Step counter ───────────────────────────────────────────────────────────

  /// The last raw reading of the phone's step counter, and when it was taken.
  Future<StepCounterReading?> readStepCounter() async {
    final raw = await _db.readValue(_stepCounterKey);
    if (raw == null) return null;
    final json = _decode(raw);
    return StepCounterReading(
      count: (json['count'] as num).toInt(),
      at: DateTime.fromMillisecondsSinceEpoch((json['at'] as num).toInt()),
    );
  }

  Future<void> writeStepCounter(StepCounterReading reading) => _db.writeValue(
    _stepCounterKey,
    jsonEncode({
      'count': reading.count,
      'at': reading.at.millisecondsSinceEpoch,
    }),
  );

  static Map<String, Object?> _decode(String raw) =>
      (jsonDecode(raw) as Map<String, dynamic>).cast<String, Object?>();
}

/// One reading of the cumulative step counter.
class StepCounterReading {
  const StepCounterReading({required this.count, required this.at});

  /// Steps since the phone last booted.
  final int count;
  final DateTime at;
}
