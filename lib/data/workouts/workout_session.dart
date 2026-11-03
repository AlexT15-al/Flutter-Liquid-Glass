import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/body_profile.dart';
import '../../domain/intervals.dart';
import '../../domain/route.dart';
import '../location/location_tracker.dart';
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
///
/// Outdoors the route comes from GPS: fixes taken while running are kept, each
/// stamped with the moving time and the stretch of moving it belongs to, and
/// distance, pace, climb and splits are read off them. Without a single good
/// fix (indoors, or GPS refused) distance falls back to the step counter.
class WorkoutSession extends ChangeNotifier {
  WorkoutSession({
    required this.type,
    required this.goal,
    required this._profile,
    required ValueListenable<int?> stepCounter,
    Stream<RoutePoint>? locations,
    this.locationAccess,
    CustomWorkout? custom,
    Duration? autoPause,
    DateTime Function()? clock,
  }) : autoPause = type.hasDistance ? autoPause : null,
       _counter = stepCounter,
       _clock = clock ?? DateTime.now,
       intervals = custom == null ? null : IntervalTracker(custom) {
    _counter.addListener(_onSteps);
    _locations = locations?.listen(_onFix);
  }

  final WorkoutType type;
  final WorkoutGoal goal;

  /// How long without moving before the workout pauses itself; null when
  /// it does not, as for one that does not move (strength, yoga).
  final Duration? autoPause;

  /// Paused by itself, not by the user: it resumes by itself too.
  bool get autoPaused => _autoPaused && _phase == SessionPhase.paused;
  bool _autoPaused = false;

  /// The last time steps were counted or the route moved on.
  DateTime? _lastMove;

  /// While paused by itself: the steps since, and where it stopped, to
  /// tell walking off again from shifting about.
  int _stepsWhilePaused = 0;
  RoutePoint? _pausedAt;

  /// Steps, or metres, that mean moving again.
  static const _resumeSteps = 6;
  static const _resumeMetres = 15.0;

  /// For a custom workout, where it is in its intervals.
  final IntervalTracker? intervals;

  /// Counts the segments started, so a listener can tell when a new one
  /// begins and give the cue.
  int get segmentChanges => _segmentChanges;
  int _segmentChanges = 0;

  /// For an outdoor workout, whether GPS could be used; null indoors.
  final LocationAccess? locationAccess;
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

  StreamSubscription<RoutePoint>? _locations;
  final List<RoutePoint> _route = [];
  int _segment = 0;

  /// Kept up to date as fixes arrive rather than summed on every read: the
  /// screen asks several times a second.
  double _routeM = 0;

  /// Fixes closer than this to the last one kept are dropped: standing still,
  /// GPS wanders a few metres and would add distance nobody moved.
  static const double _minStepM = 3;

  /// The route so far.
  List<RoutePoint> get route => List.unmodifiable(_route);

  /// Whether GPS has given anything usable yet.
  bool get hasRoute => _route.length > 1;

  /// Whether this workout listens to GPS at all.
  bool get followsGps => _locations != null;

  /// Where the phone is, for the map's position dot: the latest fix in any
  /// phase, so the map can show it during the countdown and while paused.
  RoutePoint? get position => _position;
  RoutePoint? _position;

  DateTime? get startedAt => _startedAt;

  /// Moving time: running stretches only.
  Duration get elapsed {
    final running = _phase == SessionPhase.running && _resumedAt != null
        ? _clock().difference(_resumedAt!)
        : Duration.zero;
    return _banked + running;
  }

  int get steps => _steps;

  /// From the route when there is one; otherwise from the step counter for
  /// walking and running; nothing for the rest.
  double get distanceKm {
    if (hasRoute) return _routeM / 1000;
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

  /// Average minutes per kilometre, or null before there is any distance.
  Duration? get pace {
    final km = distanceKm;
    if (km < 0.05) return null;
    return Duration(milliseconds: (elapsed.inMilliseconds / km).round());
  }

  /// Pace over the last half minute, from GPS.
  Duration? get currentPace => RouteMath.recentPace(_route);

  /// Metres climbed, from GPS altitude.
  double get elevationGainM => RouteMath.elevationGainM(_route);

  List<RouteSplit> get splits => RouteMath.splits(_route);

  double? get goalProgress =>
      goal.progress(elapsed: elapsed, distanceKm: distanceKm, kcal: activeKcal);

  /// Ends the countdown and starts the clock.
  void begin() {
    if (_phase != SessionPhase.countdown) return;
    final now = _clock();
    _startedAt = now;
    _resumedAt = now;
    _lastMove = now;
    _lastCount = _counter.value;
    _phase = SessionPhase.running;
    _startTicking();
    notifyListeners();
  }

  void pause() {
    if (_phase != SessionPhase.running) return;
    _autoPaused = false;
    _banked = elapsed;
    _resumedAt = null;
    _phase = SessionPhase.paused;
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_phase != SessionPhase.paused) return;
    _autoPaused = false;
    _resumedAt = _clock();
    _lastMove = _resumedAt;
    // Whatever was walked while paused is not bridged.
    if (_route.isNotEmpty) _segment++;
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
    // GPS off the moment the workout ends: on Android this also stops the
    // foreground service and takes its notification down.
    _locations?.cancel();
    _locations = null;
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
    elevationGainM: hasRoute ? elevationGainM : 0,
    route: List.unmodifiable(_route),
  );

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      _checkAutoPause();
      _advance();
      notifyListeners();
    });
  }

  /// Still for longer than [autoPause]: paused, as from when the moving
  /// stopped, so the time stood still is not the workout's.
  void _checkAutoPause() {
    final wait = autoPause;
    final last = _lastMove;
    final resumed = _resumedAt;
    if (wait == null || last == null || resumed == null) return;
    if (_phase != SessionPhase.running) return;
    final now = _clock();
    if (now.difference(last) < wait) return;
    final stoppedAt = last.isAfter(resumed) ? last : resumed;
    _banked += stoppedAt.difference(resumed);
    _resumedAt = null;
    _phase = SessionPhase.paused;
    _autoPaused = true;
    _stepsWhilePaused = 0;
    _pausedAt = _position;
    _timer?.cancel();
    notifyListeners();
  }

  /// Moving again after pausing by itself: carries on, counting the steps
  /// that told it so.
  void _autoResume() {
    final steps = _stepsWhilePaused;
    resume();
    _steps += steps;
  }

  /// Moves the intervals on with the clock and the distance.
  void _advance() {
    final tracker = intervals;
    if (tracker == null || _phase != SessionPhase.running) return;
    if (tracker.update(elapsed, distanceKm)) _segmentChanges++;
  }

  /// Ends the interval under way now and starts the next.
  void skipSegment() {
    final tracker = intervals;
    if (tracker == null || tracker.done) return;
    tracker.update(elapsed, distanceKm);
    tracker.skip();
    _segmentChanges++;
    notifyListeners();
  }

  void _onFix(RoutePoint fix) {
    if (_phase == SessionPhase.ended) return;
    _position = fix;
    if (_phase != SessionPhase.running) {
      final from = _pausedAt;
      if (autoPaused) {
        if (from == null) {
          _pausedAt = fix;
        } else if (RouteMath.distanceM(from, fix) >= _resumeMetres) {
          _autoResume();
          return;
        }
      }
      notifyListeners();
      return;
    }
    final stamped = fix.withProgress(elapsed: elapsed, segment: _segment);
    final last = _route.isEmpty ? null : _route.last;
    if (last != null && last.segment == _segment) {
      final step = RouteMath.distanceM(last, stamped);
      if (step < _minStepM) return;
      _routeM += step;
      _lastMove = _clock();
    }
    _route.add(stamped);
    _advance();
    notifyListeners();
  }

  void _onSteps() {
    final count = _counter.value;
    if (count == null) return;
    final last = _lastCount;
    _lastCount = count;
    if (last == null) return;
    // A lower total means the phone rebooted mid-workout; the new total is
    // all new steps.
    final added = count >= last ? count - last : count;
    if (autoPaused) {
      _stepsWhilePaused += added;
      if (_stepsWhilePaused >= _resumeSteps) _autoResume();
      return;
    }
    if (_phase != SessionPhase.running) return;
    _steps += added;
    if (added > 0) _lastMove = _clock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locations?.cancel();
    _counter.removeListener(_onSteps);
    super.dispose();
  }
}
