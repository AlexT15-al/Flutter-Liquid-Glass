import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../data/preferences/halo_preferences.dart';
import '../../data/sleep/sleep_repository.dart';
import '../../data/sleep/sleep_sensor.dart';
import '../../domain/phone_use.dart';
import '../../domain/sleep.dart';
import '../../platform/android_permissions.dart';
import '../../platform/screen_history.dart';

/// Sleep as the phone sees it.
///
/// First, the Samsung way: every time the app opens, the night just gone is
/// worked out from when the phone was last used and first unlocked
/// ([detected]), offered to be recorded as it is or with the times changed.
/// Second, for anyone who wants stages: a night tracked on the mattress,
/// whether it is being tracked, and since when.
///
/// The night lives in the database from the moment it starts, minute by
/// minute, so a phone that restarts or an app that is closed in the night
/// loses at most the minutes after that; [restore] picks it up again.
class SleepController extends ChangeNotifier {
  SleepController({
    required this.repository,
    this._sensor = const SleepSensor(),
    this._history = const ScreenHistory(),
    this._preferences,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SleepRepository repository;
  final SleepSensor _sensor;
  final ScreenHistory _history;
  final HaloPreferences? _preferences;
  final DateTime Function() _clock;

  SleepEstimate? _detected;

  /// Last night as the phone's use tells it, not yet recorded.
  SleepEstimate? get detected => _detected;

  bool? _usageAccess;

  /// Whether Halo may read the screen history: null where there is none to
  /// read (iOS), false until the user allows it.
  bool? get usageAccess => _usageAccess;

  /// Looks for last night in the phone's use. Run at launch and every time
  /// the app comes back, so it is there the first time the phone is opened
  /// in the morning.
  Future<void> detect() async {
    if (!_history.supported) {
      _usageAccess = null;
      return;
    }
    final access = await _history.hasAccess();
    SleepEstimate? found;
    if (access && !tracking) {
      final now = _clock();
      final morning = DateTime(now.year, now.month, now.day);
      // From midday before, so the state of the screen at 18:00 is known.
      final events = await _history.events(
        morning.subtract(const Duration(hours: 12)),
        now,
      );
      found = PhoneUseSleep.estimate(events, now);
      if (found != null) {
        final dismissed = await _preferences?.readDismissedSleep();
        if (dismissed == found.start ||
            await repository.overlaps(found.start, found.end)) {
          found = null;
        }
      }
    }
    if (access == _usageAccess && found?.start == _detected?.start) return;
    _usageAccess = access;
    _detected = found;
    notifyListeners();
  }

  /// Opens the Settings page where Usage Access is allowed.
  Future<void> requestUsageAccess() => _history.requestAccess();

  /// Keeps the detected night, between [from] and [to] if the user changed
  /// the times.
  Future<SleepNight?> record({DateTime? from, DateTime? to}) async {
    final estimate = _detected;
    if (estimate == null) return null;
    final night = estimate.toNight(from: from, to: to);
    final id = await repository.addNight(night);
    _detected = null;
    notifyListeners();
    return SleepNight(
      id: id,
      source: night.source,
      inBed: night.inBed,
      outOfBed: night.outOfBed,
      hypnogram: night.hypnogram,
    );
  }

  /// It was not sleep: the phone was left somewhere. Not offered again.
  Future<void> dismiss() async {
    final estimate = _detected;
    if (estimate == null) return;
    _detected = null;
    notifyListeners();
    await _preferences?.setDismissedSleep(estimate.start);
  }

  int? _sessionId;
  DateTime? _since;
  StreamSubscription<(int, int)>? _minutes;

  bool get tracking => _sessionId != null;

  /// When the night being tracked began.
  DateTime? get since => _since;

  /// Picks up a night left open: still being tracked, or tracking stopped
  /// without the app (the service was killed), in which case it is closed
  /// where its record ends.
  Future<void> restore() async {
    final open = await repository.open();
    if (open == null) return;
    final (id, start) = open;
    if (await _sensor.isRunning()) {
      _sessionId = id;
      _since = start;
      _listen(id);
      notifyListeners();
      return;
    }
    final last = await repository.lastMinute(id);
    if (last < 0) {
      await repository.delete(id);
    } else {
      await repository.finish(id, start.add(Duration(minutes: last + 1)));
    }
  }

  /// Starts tracking. Asks for Physical Activity first, which Android needs
  /// to keep the sensor running in the background, and for notifications,
  /// which show that it does.
  Future<void> start() async {
    if (tracking) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await AndroidPermissions.request(
          AndroidPermissions.activityRecognition,
        );
        await AndroidPermissions.request(AndroidPermissions.postNotifications);
      } on MissingPluginException {
        // Tests.
      }
    }
    final now = _clock();
    final id = await repository.begin(now);
    _sessionId = id;
    _since = now;
    _listen(id);
    notifyListeners();
    await _sensor.start(now);
  }

  /// Ends the night now and works it out.
  Future<SleepNight?> stop() async {
    final id = _sessionId;
    if (id == null) return null;
    await _sensor.stop();
    // The minute in progress arrives just after the sensor stops.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _minutes?.cancel();
    _minutes = null;
    final night = await repository.finish(id, _clock());
    _sessionId = null;
    _since = null;
    notifyListeners();
    return night;
  }

  /// Stops without keeping anything: started by mistake.
  Future<void> cancel() async {
    final id = _sessionId;
    if (id == null) return;
    await _sensor.stop();
    await _minutes?.cancel();
    _minutes = null;
    await repository.delete(id);
    _sessionId = null;
    _since = null;
    notifyListeners();
  }

  void _listen(int id) {
    _minutes?.cancel();
    _minutes = _sensor.minutes().listen(
      (m) => repository.putMinute(id, m.$1, m.$2),
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    _minutes?.cancel();
    super.dispose();
  }
}

/// Gives the pages tonight's controller.
class SleepScope extends InheritedNotifier<SleepController> {
  const SleepScope({
    super.key,
    required SleepController controller,
    required super.child,
  }) : super(notifier: controller);

  static SleepController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SleepScope>()!.notifier!;

  static SleepController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SleepScope>()!.notifier!;
}
