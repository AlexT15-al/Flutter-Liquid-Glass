import 'package:flutter/services.dart';

/// Where a runtime permission stands.
enum PermissionState {
  granted,

  /// Not granted, and the app may still ask.
  denied,

  /// Refused for good: Android will not show the prompt again, and only the
  /// app's page in Settings can change it.
  permanentlyDenied,
}

/// Android runtime permissions, answered by `MainActivity` over a method
/// channel rather than a plugin: the app needs two permissions, and a plugin
/// would bring its own compile-SDK requirements with it.
abstract final class AndroidPermissions {
  static const _channel = MethodChannel('halo/permissions');

  static const activityRecognition = 'android.permission.ACTIVITY_RECOGNITION';

  static Future<PermissionState> status(String permission) async =>
      _parse(await _channel.invokeMethod<String>(
        'status',
        {'permission': permission},
      ));

  /// Shows the system prompt if it still can, and returns the outcome.
  static Future<PermissionState> request(String permission) async =>
      _parse(await _channel.invokeMethod<String>(
        'request',
        {'permission': permission},
      ));

  /// Opens the app's page in system Settings.
  static Future<void> openSettings() => _channel.invokeMethod('openSettings');

  static PermissionState _parse(String? value) => switch (value) {
        'granted' => PermissionState.granted,
        'permanentlyDenied' => PermissionState.permanentlyDenied,
        _ => PermissionState.denied,
      };
}
