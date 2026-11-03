import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'android_permissions.dart';

/// What the live workout shows outside the app.
@immutable
class LiveActivityState {
  const LiveActivityState({
    required this.title,
    required this.symbol,
    required this.elapsed,
    required this.clock,
    required this.paused,
    required this.energy,
    this.distance,
    this.pace,
    this.progress,
    this.goal,
    this.gps = false,
    this.quiet = false,
  });

  final String title;

  /// The SF Symbol for the workout, for iOS.
  final String symbol;
  final Duration elapsed;

  /// [elapsed] as the app writes it, for where the time cannot run on its own.
  final String clock;
  final bool paused;
  final String energy;
  final String? distance;
  final String? pace;

  /// Towards the goal, 0 to 1, if there is one.
  final double? progress;
  final String? goal;

  /// Follows GPS, which on Android needs the recording service.
  final bool gps;

  /// Live Activity turned off: on Android only the plain notification that
  /// recording a route requires; on iOS nothing.
  final bool quiet;

  Map<String, Object?> toMap() => {
    'title': title,
    'symbol': symbol,
    'elapsedMs': elapsed.inMilliseconds,
    'clock': clock,
    'paused': paused,
    'energy': energy,
    'distance': distance,
    'pace': pace,
    'progress': progress,
    'goal': goal,
    'gps': gps,
    'quiet': quiet,
  };

  /// Whether showing [other] instead would change anything a person sees,
  /// leaving aside the time, which runs on its own.
  bool looksLike(LiveActivityState other) =>
      title == other.title &&
      paused == other.paused &&
      energy == other.energy &&
      distance == other.distance &&
      pace == other.pace &&
      goal == other.goal &&
      quiet == other.quiet &&
      ((progress ?? -1) * 100).round() ==
          ((other.progress ?? -1) * 100).round();
}

/// The workout in progress outside the app.
///
/// On Android an ongoing notification that asks to be a Live Update (the
/// status bar chip, the lock screen card, the Now Bar on One UI 8), posted by
/// a foreground service that keeps the workout recording. On iOS a Live
/// Activity: the lock screen and the Dynamic Island.
class LiveActivity {
  const LiveActivity();

  static const _channel = MethodChannel('halo/live_activity');

  /// Taps and buttons on it: `open`, `pause`, `resume`.
  void listen(void Function(String event) onEvent) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'open':
          onEvent('open');
        case 'action':
          if (call.arguments case final String action) onEvent(action);
      }
    });
  }

  /// Asks for what it needs before a workout starts, from the Start button:
  /// on Android 13 and later, notifications.
  Future<void> prepare() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await AndroidPermissions.request(AndroidPermissions.postNotifications);
    } on MissingPluginException {
      // Tests and unsupported platforms.
    }
  }

  Future<void> start(LiveActivityState state) =>
      _invoke('start', state.toMap());

  Future<void> update(LiveActivityState state) =>
      _invoke('update', state.toMap());

  Future<void> end() => _invoke('end');

  /// Posts Now Bar test notification [variant] (1 to 4), or takes it down
  /// with 0; says whether Android allows the app promoted notifications.
  Future<String> test(int variant) async {
    try {
      return await _channel.invokeMethod<String>('test', variant) ?? 'n/a';
    } on MissingPluginException {
      return 'n/a';
    } on PlatformException catch (error) {
      return error.message ?? 'error';
    }
  }

  Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Tests, and platforms with nothing to show it on.
    } on PlatformException catch (error) {
      debugPrint('Live activity $method failed: ${error.message}');
    }
  }
}
