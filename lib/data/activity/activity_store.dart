import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/activity_goals.dart';
import '../../domain/activity_summary.dart';
import '../../domain/body_profile.dart';
import '../database/app_database.dart';
import '../preferences/halo_preferences.dart';
import 'activity_math.dart';
import 'step_tracker.dart';

/// The last week of movement, in memory, kept current as steps arrive.
///
/// A week of spans is a few thousand rows at most, so holding it in memory and
/// summarising on demand is cheaper than querying the database on every
/// rebuild, and it lets the open span from the tracker count live, before it
/// has been written.
///
/// Rebuilds are coalesced: the step counter can report every step, and the
/// rings do not need to redraw faster than the eye can follow a number.
class ActivityStore extends ChangeNotifier {
  ActivityStore({
    required AppDatabase database,
    required this._preferences,
    DateTime Function()? clock,
  })  : _db = database,
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final HaloPreferences _preferences;
  final DateTime Function() _clock;

  /// How many days of spans are kept in memory, today included.
  static const windowDays = 7;

  /// The shortest gap between two rebuilds caused by live steps.
  static const _liveRefresh = Duration(milliseconds: 500);

  final List<StepSpan> _spans = [];
  StepTracker? _tracker;

  BodyProfile _profile = BodyProfile.fallback;
  ActivityGoals _goals = ActivityGoals.fallback;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _refresh;
  bool _loaded = false;

  /// Bumped whenever the inputs change; memoised summaries carry the version
  /// they were computed at.
  int _version = 0;
  final Map<DateTime, (int, ActivitySummary)> _memo = {};

  bool get isLoaded => _loaded;
  ActivityGoals get goals => _goals;
  BodyProfile get profile => _profile;

  /// Reads the week from storage and follows the profile and goals.
  Future<void> load() async {
    final now = _clock();
    final from = DateTime(now.year, now.month, now.day - (windowDays - 1));
    final rows = await _db.stepIntervalsBetween(
      from,
      now.add(const Duration(days: 1)),
    );
    _spans
      ..clear()
      ..addAll(rows.map(_spanFrom));

    _subscriptions
      ..add(_preferences.watchProfile().listen((value) {
        _profile = value;
        _changed();
      }))
      ..add(_preferences.watchGoals().listen((value) {
        _goals = value;
        _changed();
      }));

    _loaded = true;
    _changed();
  }

  /// Connects the live tracker: its finished spans are stored through here,
  /// and its open span counts towards today as it grows.
  void attach(StepTracker tracker) {
    _tracker = tracker;
    tracker.pending.addListener(_onLiveSteps);
  }

  /// Stores a finished span from the tracker.
  Future<void> addSpan(StepSpan span) async {
    await _db.insertStepInterval(
      start: span.start,
      end: span.end,
      steps: span.steps,
    );
    _spans.add(span);
    _prune();
    _changed();
  }

  /// Today so far, including steps still in the tracker's open span.
  ActivitySummary get today => summaryFor(_clock());

  /// The summary for the day containing [day].
  ActivitySummary summaryFor(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final cached = _memo[key];
    if (cached != null && cached.$1 == _version) return cached.$2;

    final open = _tracker?.pending.value;
    final summary = ActivityMath.summarize(
      spans: open == null ? _spans : [..._spans, open],
      day: key,
      profile: _profile,
    );
    _memo[key] = (_version, summary);
    return summary;
  }

  /// The last [count] days, oldest first, today last.
  List<ActivitySummary> lastDays(int count) {
    final now = _clock();
    return [
      for (var i = count - 1; i >= 0; i--)
        summaryFor(DateTime(now.year, now.month, now.day - i)),
    ];
  }

  void _onLiveSteps() {
    if (_refresh?.isActive ?? false) return;
    _refresh = Timer(_liveRefresh, _changed);
  }

  void _changed() {
    _version++;
    notifyListeners();
  }

  /// Drops spans that have fallen out of the window, so an app left running
  /// for weeks does not keep every step it ever saw.
  void _prune() {
    final now = _clock();
    final cutoff = DateTime(now.year, now.month, now.day - windowDays);
    _spans.removeWhere((span) => span.end.isBefore(cutoff));
    _memo.removeWhere((day, _) => day.isBefore(cutoff));
  }

  static StepSpan _spanFrom(StepInterval row) => StepSpan(
        start: DateTime.fromMillisecondsSinceEpoch(row.startMs),
        end: DateTime.fromMillisecondsSinceEpoch(row.endMs),
        steps: row.steps,
      );

  @override
  void dispose() {
    _refresh?.cancel();
    _tracker?.pending.removeListener(_onLiveSteps);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
