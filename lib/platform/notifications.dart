import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/notifications.dart';

/// `halo/notifications`: hands the planned reminders to the phone, which
/// shows them at their time with the app closed, and keeps it up to date
/// with what they check (today's water, the last weigh-in…).
///
/// A tap on one comes back as the screen to open.
class Reminders {
  const Reminders();

  static const _channel = MethodChannel('halo/notifications');

  static final _opens = StreamController<String>.broadcast();

  /// Screens to open, from taps on reminders while the app runs.
  static Stream<String> get opens => _opens.stream;

  static bool _listening = false;

  /// Starts passing taps on. Once, early.
  static void listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) {
        _opens.add(call.arguments as String);
      }
    });
  }

  /// The screen a tap on a reminder launched the app to, once.
  Future<String?> launchRoute() => _invoke<String>('launchRoute');

  /// Replaces every reminder to come with [planned].
  Future<void> schedule(List<PlannedNotification> planned) =>
      _invoke('schedule', [for (final p in planned) p.toJson()]);

  /// What the checks read: today's water, meals, workouts and the rest.
  Future<void> state(Map<String, Object?> state) => _invoke('state', state);

  /// Whether reminders can come at their exact minute; without it Android
  /// may hold them back a few minutes.
  Future<bool> exactAllowed() async =>
      await _invoke<bool>('exactAllowed') ?? true;

  /// Android's page for exact alarms.
  Future<void> openExactSettings() => _invoke('openExactSettings');

  /// Android's notification settings for Halo.
  Future<void> openSettings() => _invoke('openSettings');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      debugPrint('Reminders $method failed: ${error.message}');
      return null;
    }
  }
}
