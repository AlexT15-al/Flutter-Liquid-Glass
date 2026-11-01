import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/activity_goals.dart';
import '../../domain/activity_summary.dart';
import '../../domain/body_profile.dart';
import '../../domain/mindfulness.dart';
import '../../domain/notifications.dart';
import '../../domain/nutrition.dart';
import '../../domain/sleep.dart';
import '../../domain/training.dart';
import '../../domain/weekly.dart';
import '../../platform/notifications.dart';
import '../activity/activity_history.dart';
import '../activity/activity_store.dart';
import '../activity/step_tracker.dart';
import '../database/app_database.dart';
import '../mindfulness/mindfulness_repository.dart';
import '../nutrition/nutrition_repository.dart';
import '../preferences/halo_preferences.dart';
import '../training/training_repository.dart';
import '../workouts/workout_repository.dart';

/// Keeps the phone's reminders in step with the settings and the data.
///
/// Two things go to the phone: the plan (every reminder of the next week,
/// worked out again whenever what it depends on changes) and the state its
/// checks read at the time (today's water, meals, workouts, steps, the last
/// weigh-in), so a reminder that has nothing left to say stays quiet even
/// with the app closed.
class NotificationSync {
  NotificationSync({
    required this._database,
    required this._preferences,
    required this._activity,
    required this._steps,
    required this._workouts,
    required this._nutrition,
    required this._training,
    required this._mindfulness,
    this._reminders = const Reminders(),
  });

  final AppDatabase _database;
  final HaloPreferences _preferences;
  final ActivityStore _activity;
  final StepTracker _steps;
  final WorkoutRepository _workouts;
  final NutritionRepository _nutrition;
  final TrainingRepository _training;
  final MindfulnessRepository _mindfulness;
  final Reminders _reminders;

  final List<StreamSubscription<Object?>> _subs = [];
  final List<StreamSubscription<Object?>> _todaySubs = [];
  AppLifecycleListener? _lifecycle;
  Timer? _replan;
  DateTime? _day;

  NotificationSettings _settings = const NotificationSettings();
  SleepSchedule _sleep = const SleepSchedule();
  TrainingProfile? _trainingProfile;
  BodyProfile _body = BodyProfile.fallback;
  WeightGoal _goal = const WeightGoal();
  ActivityGoals _goals = ActivityGoals.fallback;
  List<SetLog> _history = const [];
  int _stepStreak = 0;
  String? _weeklyHeadline;

  final Map<String, Object?> _state = {};

  void attach() {
    _subs.addAll([
      _preferences.watchNotifications().listen((v) {
        _settings = v;
        _schedule();
      }),
      _preferences.watchSleepSchedule().listen((v) {
        _sleep = v;
        _schedule();
      }),
      _preferences.watchTraining().listen((v) {
        _trainingProfile = v;
        _schedule();
      }),
      _preferences.watchProfile().listen((v) {
        _body = v;
        _schedule();
      }),
      _preferences.watchWeightGoal().listen((v) {
        _goal = v;
        _schedule();
      }),
      _preferences.watchGoals().listen((v) {
        _goals = v;
        _schedule();
      }),
      _training.watchHistory().listen((v) {
        _history = v;
        _schedule();
      }),
      _nutrition.watchWeights(limit: 1).listen((v) {
        _setState({
          'lastWeighMs': v.isEmpty ? 0 : v.first.$1.millisecondsSinceEpoch,
        });
      }),
    ]);
    _activity.addListener(_onSteps);
    _steps.latestCount.addListener(_onSteps);
    _lifecycle = AppLifecycleListener(
      onResume: _onDay,
      onHide: () => _onSteps(force: true),
    );
    _onDay();
  }

  void dispose() {
    for (final s in [..._subs, ..._todaySubs]) {
      s.cancel();
    }
    _activity.removeListener(_onSteps);
    _steps.latestCount.removeListener(_onSteps);
    _lifecycle?.dispose();
    _replan?.cancel();
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Follows today's data, again after midnight, and works out what only
  /// changes from day to day: the streak, Monday's headline.
  void _onDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_day == today) return;
    _day = today;
    for (final s in _todaySubs) {
      s.cancel();
    }
    _todaySubs.clear();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final key = _key(today);
    _todaySubs.addAll([
      _workouts.watchBetween(today, tomorrow).listen((v) {
        _setState({'workoutDay': v.isEmpty ? '' : key});
      }),
      _nutrition.watchWaterOn(today).listen((v) {
        _setState({
          'waterDay': key,
          'waterMl': v.fold<int>(0, (t, e) => t + e.$2),
        });
      }),
      _nutrition.watchFoodOn(today).listen((v) {
        _setState({
          'mealsDay': key,
          'meals': [
            for (final m in {for (final e in v) e.meal}) m.name,
          ],
        });
      }),
      _mindfulness.watchSessionsSince(today).listen((v) {
        _setState({'mindfulDay': v.isEmpty ? '' : key});
      }),
    ]);
    _onSteps(force: true);
    unawaited(_daily(today));
  }

  Future<void> _daily(DateTime today) async {
    final history = ActivityHistory(_database, _workouts);
    final days = await history.days(
      DateTime(today.year, today.month, today.day - 60),
      today,
      _activity.profile,
    );
    // Days in a row up to yesterday with the step goal met.
    var streak = 0;
    for (final d in days.reversed) {
      if (d.day == today) continue;
      if (d.steps >= _activity.goals.steps) {
        streak++;
      } else {
        break;
      }
    }
    _stepStreak = streak;
    _weeklyHeadline = today.weekday == DateTime.monday
        ? await _headline(days, today)
        : null;
    _schedule();
  }

  Future<String?> _headline(List<ActivitySummary> days, DateTime today) async {
    final from = DateTime(today.year, today.month, today.day - 14);
    final workouts = await _workouts.watchBetween(from, today).first;
    final review = WeeklyReview.of(
      days: days,
      workouts: workouts,
      nights: const [],
      water: const [],
      mindful: const <MindfulSession>[],
      goals: _activity.goals,
      sleepGoal: _sleep.goal,
      waterGoalMl: 2000,
      now: today,
    );
    return review.empty || review.highlights.isEmpty
        ? null
        : review.highlights.first.title;
  }

  DateTime? _stepsSentAt;

  /// Today's steps and the counter they were read at, so the evening check
  /// can add what was walked since.
  void _onSteps({bool force = false}) {
    final now = DateTime.now();
    final sent = _stepsSentAt;
    if (!force && sent != null && now.difference(sent).inMinutes < 2) return;
    _stepsSentAt = now;
    _setState({
      'stepsDay': _key(now),
      'steps': _activity.today.steps,
      'counter': _steps.latestCount.value ?? -1,
      'counterAt': now.millisecondsSinceEpoch,
    });
  }

  void _setState(Map<String, Object?> values) {
    var changed = false;
    for (final e in values.entries) {
      final old = _state[e.key];
      if (old is List && e.value is List) {
        if (old.join(',') == (e.value as List).join(',')) continue;
      } else if (old == e.value) {
        continue;
      }
      _state[e.key] = e.value;
      changed = true;
    }
    if (changed) unawaited(_reminders.state(Map.of(_state)));
  }

  /// Works the plan out again, once things settle.
  void _schedule() {
    _replan?.cancel();
    _replan = Timer(const Duration(milliseconds: 600), () {
      final now = DateTime.now();
      final training = <int, PlannedDay>{};
      final profile = _trainingProfile;
      if (profile != null) {
        for (final s in TrainingPlanner.week(
          training: profile,
          body: _body,
          goal: _goal,
          history: _history,
        )) {
          training[s.weekday] = (title: s.title, length: s.length);
        }
      }
      unawaited(
        _reminders.schedule(
          NotificationPlanner.plan(
            settings: _settings,
            now: now,
            sleep: _sleep,
            training: training,
            stepsGoal: _goals.steps,
            stepStreak: _stepStreak,
            waterGoalMl: NutritionTargets.of(_body, _goal, today: now).waterMl,
            weeklyHeadline: _weeklyHeadline,
          ),
        ),
      );
    });
  }
}
