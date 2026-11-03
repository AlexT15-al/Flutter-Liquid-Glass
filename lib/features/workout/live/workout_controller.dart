import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../data/location/location_tracker.dart';
import '../../../data/workouts/workout_repository.dart';
import '../../../data/workouts/workout_session.dart';
import '../../../domain/body_profile.dart';
import '../../../domain/intervals.dart';
import '../../../domain/route.dart';
import '../../../domain/workout.dart';

/// The workout in progress, if any, and whether it fills the screen.
///
/// It lives above the Navigator, beside the tab bar, because the live workout
/// does: a full-screen layer over everything while it is up, and a pill above
/// the tab bar while minimised, the way Music keeps its player. A page cannot
/// own something that has to survive every push and every tab.
class WorkoutController extends ChangeNotifier {
  WorkoutController({
    required this._repository,
    required ValueListenable<int?> stepCounter,
    this._location,
    this._clock,
  }) : _counter = stepCounter;

  final WorkoutRepository _repository;
  final ValueListenable<int?> _counter;

  /// GPS for outdoor workouts; null where there is none, as in tests.
  final LocationTracker? _location;

  /// The sessions' clock; the wall clock unless a test sets it.
  final DateTime Function()? _clock;

  WorkoutSession? _session;
  WorkoutSession? get session => _session;

  bool _expanded = false;

  /// Filling the screen, as opposed to the pill.
  bool get expanded => _expanded;

  Timer? _countdown;

  /// Segments of a custom workout cued so far.
  int _segments = 0;

  /// A new interval: two firm taps, felt through a pocket or an armband,
  /// whether the workout is on screen or not.
  bool _wasAutoPaused = false;

  void _onSession() {
    final session = _session;
    if (session == null) return;
    // Paused or carried on by itself: a firm tap, felt in a pocket.
    if (session.autoPaused != _wasAutoPaused) {
      _wasAutoPaused = session.autoPaused;
      HapticFeedback.mediumImpact();
    }
    if (session.segmentChanges == _segments) return;
    _segments = session.segmentChanges;
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 180), HapticFeedback.heavyImpact);
  }

  /// Starts a workout: the countdown first, then the clock.
  ///
  /// Outdoors it asks for location first, and starts listening straight away
  /// so GPS has the countdown to find its first fix. Refused, the workout
  /// still runs, measured by steps.
  Future<void> start({
    required WorkoutType type,
    required WorkoutGoal goal,
    required BodyProfile profile,
    CustomWorkout? custom,
    Duration? autoPause,
  }) async {
    if (_session != null) return;
    final location = _location;
    LocationAccess? access;
    Stream<RoutePoint>? fixes;
    if (type.gps && location != null) {
      access = await location.ensureAccess();
      if (access == LocationAccess.granted) fixes = location.watch();
    }
    if (_session != null) return;

    final session = WorkoutSession(
      type: type,
      goal: goal,
      profile: profile,
      stepCounter: _counter,
      locations: fixes,
      locationAccess: access,
      custom: custom,
      autoPause: autoPause,
      clock: _clock,
    );
    _session = session;
    _segments = 0;
    _wasAutoPaused = false;
    session.addListener(_onSession);
    _expanded = true;
    _countdown = Timer(WorkoutSession.countdownLength, session.begin);
    notifyListeners();
  }

  /// Skips what is left of the countdown.
  void skipCountdown() {
    _countdown?.cancel();
    _session?.begin();
  }

  void expand() {
    if (_session == null || _expanded) return;
    _expanded = true;
    notifyListeners();
  }

  void minimize() {
    // A finished workout has to be saved or discarded first.
    if (!_expanded || _session?.phase == SessionPhase.ended) return;
    _expanded = false;
    notifyListeners();
  }

  /// Stores the finished workout and clears it.
  Future<void> save({int? effort}) async {
    final session = _session;
    if (session == null) return;
    final record = session.toRecord(effort: effort);
    // Too short to be a workout: a start pressed by mistake.
    if (record.activeDuration >= const Duration(seconds: 30)) {
      await _repository.save(record);
    }
    _clear();
  }

  void discard() => _clear();

  void _clear() {
    _countdown?.cancel();
    final session = _session;
    session?.removeListener(_onSession);
    _session = null;
    _expanded = false;
    notifyListeners();
    // Disposed after the frame that stops drawing it.
    WidgetsBinding.instance.addPostFrameCallback((_) => session?.dispose());
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _session?.dispose();
    super.dispose();
  }
}

/// Hands the controller to everything that shows or starts a workout.
class WorkoutScope extends InheritedNotifier<WorkoutController> {
  const WorkoutScope({
    super.key,
    required WorkoutController controller,
    required super.child,
  }) : super(notifier: controller);

  static WorkoutController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WorkoutScope>();
    assert(scope != null, 'No WorkoutScope found above this widget.');
    return scope!.notifier!;
  }

  static WorkoutController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<WorkoutScope>();
    assert(scope != null, 'No WorkoutScope found above this widget.');
    return scope!.notifier!;
  }
}
