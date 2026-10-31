import 'package:flutter/services.dart';

/// The phone's accelerometer, felt through the mattress, as minutes: how many
/// seconds of each one the bed moved. On Android it is read by a foreground
/// service, so the night is tracked with the screen off.
class SleepSensor {
  const SleepSensor();

  static const _methods = MethodChannel('halo/sleep');
  static const _events = EventChannel('halo/sleep/minutes');

  Future<bool> start(DateTime inBed) async {
    try {
      return await _methods.invokeMethod<bool>('start', {
            'startMs': inBed.millisecondsSinceEpoch,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _methods.invokeMethod<void>('stop');
    } on MissingPluginException {
      // Nothing was running.
    }
  }

  Future<bool> isRunning() async {
    try {
      return await _methods.invokeMethod<bool>('isRunning') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// `(minute since going to bed, seconds of movement in it)`.
  Stream<(int, int)> minutes() => _events.receiveBroadcastStream().map((event) {
    final map = event as Map<Object?, Object?>;
    return ((map['minute'] as num).toInt(), (map['count'] as num).toInt());
  });
}
