import 'dart:convert';

import '../../domain/activity_goals.dart';
import '../../domain/app_theme_mode.dart';
import '../../domain/body_profile.dart';
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
