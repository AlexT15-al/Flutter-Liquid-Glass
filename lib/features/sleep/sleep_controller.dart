import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../data/sleep/sleep_repository.dart';
import '../../data/sleep/sleep_sensor.dart';
import '../../domain/sleep.dart';
import '../../platform/android_permissions.dart';

/// Tonight: whether the night is being tracked, and since when.
///
/// The night lives in the database from the moment it starts, minute by
/// minute, so a phone that restarts or an app that is closed in the night
/// loses at most the minutes after that; [restore] picks it up again.
class SleepController extends ChangeNotifier {
  SleepController({
    required this.repository,
    this._sensor = const SleepSensor(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SleepRepository repository;
  final SleepSensor _sensor;
  final DateTime Function() _clock;

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
