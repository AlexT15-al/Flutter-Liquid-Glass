import 'dart:async';
import 'dart:math' as math;

import '../../../data/workouts/workout_session.dart';
import '../../../domain/workout.dart';
import '../../../platform/live_activity.dart';
import '../../../shared/format.dart';
import '../widgets/route_sections.dart';
import 'workout_controller.dart';

/// Keeps the workout's Live Activity in step with the workout.
///
/// It appears once the countdown is over, changes when the numbers a person
/// would read change (at most every few seconds, since the time runs on its
/// own), and goes the moment the workout ends. Pause, Resume and a tap on it
/// come back here and go to the workout.
class WorkoutLiveActivity {
  WorkoutLiveActivity({
    required this._controller,
    required Stream<bool> enabled,
    this._platform = const LiveActivity(),
    DateTime Function()? clock,
    int Function()? exerciseGoal,
  }) : _enabledStream = enabled,
       _clock = clock ?? DateTime.now,
       _exerciseGoal = exerciseGoal ?? (() => 30);

  final WorkoutController _controller;
  final Stream<bool> _enabledStream;
  final LiveActivity _platform;
  final DateTime Function() _clock;

  /// The day's Exercise goal in minutes: what an open workout's progress
  /// bar fills towards.
  final int Function() _exerciseGoal;

  /// Between updates, unless the workout pauses or resumes.
  static const minInterval = Duration(seconds: 5);

  StreamSubscription<bool>? _enabledSub;
  bool _enabled = true;
  WorkoutSession? _session;
  LiveActivityState? _shown;
  DateTime? _shownAt;

  void attach() {
    _platform.listen(_onEvent);
    _controller.addListener(_onController);
    _enabledSub = _enabledStream.listen((on) {
      if (on == _enabled) return;
      _enabled = on;
      // Shown the other way from now on: start over.
      if (_shown != null) {
        _shown = null;
        unawaited(_platform.end());
      }
      _onSession();
    });
    _onController();
  }

  void dispose() {
    _enabledSub?.cancel();
    _controller.removeListener(_onController);
    _session?.removeListener(_onSession);
  }

  void _onEvent(String event) {
    final session = _session;
    switch (event) {
      case 'open':
        if (session != null) _controller.expand();
      case 'pause':
        session?.pause();
      case 'resume':
        session?.resume();
    }
  }

  void _onController() {
    final session = _controller.session;
    if (session == _session) return;
    _session?.removeListener(_onSession);
    _session = session;
    session?.addListener(_onSession);
    _onSession();
  }

  void _onSession() {
    final session = _session;
    if (session == null || session.phase == SessionPhase.ended) {
      if (_shown != null) {
        _shown = null;
        unawaited(_platform.end());
      }
      return;
    }
    if (session.phase == SessionPhase.countdown) return;

    final state = stateOf(
      session,
      quiet: !_enabled,
      exerciseGoal: _exerciseGoal(),
    );
    // Turned off, an indoor workout shows nothing at all.
    if (state.quiet && !state.gps) return;

    final shown = _shown;
    final now = _clock();
    if (shown == null) {
      _shown = state;
      _shownAt = now;
      unawaited(_platform.start(state));
      return;
    }
    if (state.quiet) return;
    final due = now.difference(_shownAt!) >= minInterval;
    if (state.paused != shown.paused ||
        state.goal != shown.goal ||
        (due && !state.looksLike(shown))) {
      _shown = state;
      _shownAt = now;
      unawaited(_platform.update(state));
    }
  }

  /// What the workout looks like outside the app right now.
  static LiveActivityState stateOf(
    WorkoutSession session, {
    bool quiet = false,
    int exerciseGoal = 30,
  }) {
    final type = session.type;
    final km = session.distanceKm;
    final pace = session.followsGps
        ? session.currentPace ?? session.pace
        : session.pace;
    final hasDistance = type.hasDistance && km > 0;
    final intervals = session.intervals;
    final segment = intervals?.current;
    // A bar always, which the Now Bar draws: the goal's, the interval's, or
    // with an open goal, the minutes towards the day's Exercise goal.
    final goalProgress = session.goalProgress;
    final minutes = session.elapsed.inMinutes;
    final progress = intervals != null
        ? intervals.progress
        : goalProgress ?? (minutes / math.max(1, exerciseGoal)).clamp(0.0, 1.0);
    return LiveActivityState(
      title: type.title,
      symbol: symbolOf(type),
      elapsed: session.elapsed,
      clock: Format.clock(session.elapsed),
      paused: session.phase == SessionPhase.paused,
      energy: '${Format.integer(session.activeKcal)} kcal',
      distance: hasDistance ? '${km.toStringAsFixed(2)} km' : null,
      pace: !hasDistance || pace == null
          ? null
          : type == WorkoutType.outdoorCycle
          ? '${SplitsCard.kmh(pace).toStringAsFixed(1)} km/h'
          : '${Format.pace(pace)} /km',
      progress: progress.clamp(0.0, 1.0),
      // A custom workout shows the interval under way, which changes only
      // when the next one starts, so the update goes out straight away.
      goal: intervals != null
          ? segment == null
                ? 'Complete'
                : '${segment.label} · ${segment.step.describe}'
          : session.goal.kind == WorkoutGoalKind.open
          ? '$minutes of $exerciseGoal min exercise'
          : 'Goal ${session.goal.describe}',
      gps: session.followsGps,
      quiet: quiet,
    );
  }

  /// The SF Symbol iOS draws for each workout.
  static String symbolOf(WorkoutType type) => switch (type) {
    WorkoutType.outdoorWalk || WorkoutType.indoorWalk => 'figure.walk',
    WorkoutType.outdoorRun || WorkoutType.indoorRun => 'figure.run',
    WorkoutType.hiking => 'figure.hiking',
    WorkoutType.outdoorCycle => 'figure.outdoor.cycle',
    WorkoutType.indoorCycle => 'figure.indoor.cycle',
    WorkoutType.strength => 'figure.strengthtraining.traditional',
    WorkoutType.hiit => 'figure.highintensity.intervaltraining',
    WorkoutType.yoga => 'figure.yoga',
    WorkoutType.pilates => 'figure.pilates',
    WorkoutType.dance => 'figure.dance',
    WorkoutType.swimming => 'figure.pool.swim',
    WorkoutType.rowing => 'figure.rower',
    WorkoutType.elliptical => 'figure.elliptical',
    WorkoutType.other => 'figure.mixed.cardio',
  };
}
