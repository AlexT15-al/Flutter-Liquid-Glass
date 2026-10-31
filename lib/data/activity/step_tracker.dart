import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/activity_summary.dart';
import '../preferences/halo_preferences.dart';

/// Whether the app may read the step counter.
enum StepAccess {
  /// Not asked yet, or still finding out.
  unknown,
  granted,

  /// Refused. On Android a second refusal is permanent and only Settings can
  /// undo it.
  denied,

  /// The phone has no step counter.
  unavailable,
}

/// Turns the phone's running step total into spans of counted steps.
///
/// ## The model
///
/// Both platforms report steps since the phone booted. Each reading is
/// compared with the previous one, and the difference is the steps taken
/// between the two moments. Readings close together are gathered into one open
/// span of about a minute, which is fine enough for the cadence that decides
/// exercise minutes. A long silence (the app closed, the phone in a drawer)
/// becomes one span covering the whole gap, so its steps count without the app
/// inventing when inside the gap they happened.
///
/// ## The invariant that makes it crash-safe
///
/// The stored counter reading always marks the end of the last span written to
/// the database. Steps still sitting in the open span were counted after it.
/// If the app is killed before the open span is written, the next reading is
/// compared with the stored one and the lost steps reappear inside that gap.
/// They are never lost and never counted twice.
class StepTracker with WidgetsBindingObserver {
  StepTracker({
    required this._preferences,
    required this.onSpan,
    Stream<int> Function()? counterStream,
    DateTime Function()? clock,
    bool? requiresPermission,
  })  : _counterStream = counterStream ??
            (() => Pedometer.stepCountStream.map((event) => event.steps)),
        _clock = clock ?? DateTime.now,
        _requiresPermission =
            requiresPermission ?? defaultTargetPlatform == TargetPlatform.android;

  final HaloPreferences _preferences;
  final Stream<int> Function() _counterStream;
  final DateTime Function() _clock;

  /// Android gates the step counter behind the Activity Recognition runtime
  /// permission. iOS asks on its own the first time the counter is read.
  final bool _requiresPermission;

  /// Receives each finished span, to be stored.
  final Future<void> Function(StepSpan span) onSpan;

  /// A span is closed and written once it covers this much time.
  static const spanLength = Duration(seconds: 60);

  /// Readings further apart than this are a gap, not a continuation.
  static const maxContinuation = Duration(minutes: 2);

  /// Steps counted but not yet written: the open span, live.
  final ValueNotifier<StepSpan?> pending = ValueNotifier(null);

  final ValueNotifier<StepAccess> access = ValueNotifier(StepAccess.unknown);

  StreamSubscription<int>? _subscription;
  StepCounterReading? _stored;
  StepCounterReading? _latest;
  bool _started = false;

  /// Checks access and starts counting if it is already granted. Never asks:
  /// asking belongs to a button the user pressed.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _stored = await _preferences.readStepCounter();

    if (_requiresPermission) {
      final status = await Permission.activityRecognition.status;
      access.value = _accessFrom(status);
      if (access.value == StepAccess.granted) _listen();
    } else {
      _listen();
    }
  }

  /// Asks for access, from a button the user pressed.
  Future<void> requestAccess() async {
    if (_requiresPermission) {
      final status = await Permission.activityRecognition.request();
      access.value = _accessFrom(status);
      if (access.value == StepAccess.granted) _listen();
      if (status.isPermanentlyDenied) await openAppSettings();
    } else {
      _listen();
    }
  }

  static StepAccess _accessFrom(PermissionStatus status) => switch (status) {
        PermissionStatus.granted || PermissionStatus.limited => StepAccess.granted,
        PermissionStatus.denied ||
        PermissionStatus.permanentlyDenied ||
        PermissionStatus.restricted =>
          StepAccess.denied,
        _ => StepAccess.unknown,
      };

  void _listen() {
    if (_subscription != null) return;
    _subscription = _counterStream().listen(
      (count) => record(count, _clock()),
      onError: (Object error) {
        // No sensor at all is the one error worth showing; anything else is a
        // hiccup the next reading recovers from.
        if (error.toString().contains('not available')) {
          access.value = StepAccess.unavailable;
        }
        debugPrint('Step counter error: $error');
      },
    );
    if (access.value == StepAccess.unknown) {
      access.value = StepAccess.granted;
    }
  }

  /// Readings are handled one at a time, in arrival order. Handling one
  /// awaits storage, and a reading that arrived meanwhile must not see the
  /// open span half-written.
  Future<void> _queue = Future.value();

  /// Feeds one reading of the cumulative counter. Public for tests.
  @visibleForTesting
  Future<void> record(int count, DateTime at) =>
      _queue = _queue.then((_) => _record(count, at));

  Future<void> _record(int count, DateTime at) async {
    final previous = _latest ?? _stored;
    _latest = StepCounterReading(count: count, at: at);

    if (previous == null) {
      // The very first reading after install. Steps before it cannot be
      // attributed to any time, so it only sets the baseline.
      _stored = _latest;
      await _preferences.writeStepCounter(_latest!);
      return;
    }

    // A total lower than the last one means the phone rebooted and the counter
    // started again from zero: everything it holds now is new.
    final delta = count >= previous.count ? count - previous.count : count;
    final open = pending.value;

    if (at.difference(previous.at) > maxContinuation) {
      // A gap. Close what was open, then the gap is a span of its own.
      await _flush(upTo: previous);
      if (delta > 0) {
        await _write(StepSpan(start: previous.at, end: at, steps: delta));
      }
      await _commit(_latest!);
      return;
    }

    if (delta > 0) {
      pending.value = StepSpan(
        start: open?.start ?? previous.at,
        end: at,
        steps: (open?.steps ?? 0) + delta,
      );
    }

    final current = pending.value;
    if (current != null && current.duration >= spanLength) {
      await _flush(upTo: _latest!);
    }
  }

  /// Writes the open span, if any, and moves the stored reading to [upTo].
  Future<void> _flush({required StepCounterReading upTo}) async {
    final open = pending.value;
    if (open == null) return;
    pending.value = null;
    await _write(open);
    await _commit(upTo);
  }

  Future<void> _write(StepSpan span) => onSpan(span);

  Future<void> _commit(StepCounterReading reading) async {
    _stored = reading;
    await _preferences.writeStepCounter(reading);
  }

  /// Writes what is open when the app goes to the background, so a kill there
  /// loses nothing in memory, and listens again on return, when the first
  /// reading turns the time away into a gap span.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _queue = _queue.then((_) async {
          final latest = _latest;
          if (latest != null) await _flush(upTo: latest);
        });
      case AppLifecycleState.resumed:
        if (access.value == StepAccess.granted && _subscription == null) {
          _listen();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
    await _queue;
    final latest = _latest;
    if (latest != null) await _flush(upTo: latest);
    pending.dispose();
    access.dispose();
  }
}
