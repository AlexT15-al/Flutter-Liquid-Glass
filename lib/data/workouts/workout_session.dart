import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/body_profile.dart';
import '../../domain/workout.dart';

/// Where a live workout is.
enum SessionPhase { countdown, running, paused, ended }

/// One workout in progress: its clock, its steps and the numbers built on
/// them.
///
/// Time is read from the wall clock, never accumulated from ticks, so a frame
/// dropped or the app sent to the background never loses a second. Steps come
/// from the phone's cumulative counter: the difference between readings while
/// running, so steps taken during a pause do not count.
class WorkoutSession extends ChangeNotifier {
  WorkoutSession({
    required this.type,
    required this.goal,
    required this._profile,
    required ValueListenable<int?> stepCounter,
    DateTime Function()? clock,
  })  : _counter = stepCounter,
        _clock = clock ?? DateTime.now {
    _counter.addListener(_onSteps);
  }

  final WorkoutType type;
  final WorkoutGoal goal;
  final BodyProfile _profile;
  final ValueListenable<int?> _counter;
  final DateTime Function() _clock;

  /// How long the 3-2-1 lasts.
  static const countdownLength = Duration(seconds: 3);

  /// How often the clock on screen is refreshed while running. Faster than a
  /// second, so the seconds turn over on time rather than up to a second late.
  static const _tick = Duration(milliseconds: 250);

  SessionPhase _phase = SessionPhase.countdown;
  SessionPhase get phase => _phase;

  DateTime? _startedAt;
  DateTime? _endedAt;
  DateTime? _resumedAt;
  Duration _banked = Duration.zero;

  int _steps = 0;
  int? _lastCount;
  Timer? _timer;

  DateTime? get startedAt => _startedAt;

  /// Moving time: running stretches only.
  Duration get elapsed {
    final running = _phase == SessionPhase.running && _resumedAt != null
        ? _clock().difference(_resumedAt!)
        : Duration.zero;
    return _banked + running;
  }

  int get steps => _steps;

  /// From the step counter for walking and running; nothing the phone can
  /// measure for the rest until GPS arrives.
  double get distanceKm {
    if (!type.steps) return 0;
    final running =
        type == WorkoutType.outdoorRun || type == WorkoutType.indoorRun;
    return _steps * _profile.walkingStrideMeters * (running ? 1.3 : 1) / 1000;
  }

  /// Energy above resting: `(MET − 1) × kg × hours`.
  double get activeKcal {
    final hours = elapsed.inMilliseconds / Duration.millisecondsPerHour;
    return (type.met - 1) * _profile.weightKg * hours;
  }

  /// Minutes per kilometre, or null before there is any distance.
  Duration? get pace {
    final km = distanceKm;
    if (km < 0.05) return null;
    return Duration(milliseconds: (elapsed.inMilliseconds / km).round());
  }

  double? get goalProgress => goal.progress(
        elapsed: elapsed,
        distanceKm: distanceKm,
        kcal: activeKcal,
      );

  /// Ends the countdown and starts the clock.
  void begin() {
    if (_phase != SessionPhase.countdown) return;
    final now = _clock();
    _startedAt = now;
    _resumedAt = now;
    _lastCount = _counter.value;
    _phase = SessionPhase.running;
    _startTicking();
    notifyListeners();
  }

  void pause() {
    if (_phase != SessionPhase.running) return;
    _banked = elapsed;
    _resumedAt = null;
    _phase = SessionPhase.paused;
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_phase != SessionPhase.paused) return;
    _resumedAt = _clock();
    // Steps taken while paused are not the workout's.
    _lastCount = _counter.value;
    _phase = SessionPhase.running;
    _startTicking();
    notifyListeners();
  }

  void end() {
    if (_phase == SessionPhase.ended) return;
    if (_phase == SessionPhase.running) _banked = elapsed;
    _resumedAt = null;
    _endedAt = _clock();
    _startedAt ??= _endedAt;
    _phase = SessionPhase.ended;
    _timer?.cancel();
    notifyListeners();
  }

  /// The finished workout, ready to store.
  WorkoutRecord toRecord({int? effort}) => WorkoutRecord(
        type: type,
        start: _startedAt ?? _clock(),
        end: _endedAt ?? _clock(),
        activeDuration: elapsed,
        distanceKm: distanceKm,
        activeKcal: activeKcal,
        steps: _steps,
        effort: effort,
      );

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => notifyListeners());
  }

  void _onSteps() {
    final count = _counter.value;
    if (count == null) return;
    final last = _lastCount;
    _lastCount = count;
    if (_phase != SessionPhase.running || last == null) return;
    // A lower total means the phone rebooted mid-workout; the new total is
    // all new steps.
    _steps += count >= last ? count - last : count;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _counter.removeListener(_onSteps);
    super.dispose();
  }
}
