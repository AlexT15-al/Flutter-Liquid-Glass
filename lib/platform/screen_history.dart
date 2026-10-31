import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/phone_use.dart';

/// When the screen went on and off and the phone was unlocked, from
/// Android's usage history. Needs Usage Access, granted in Settings. Nothing
/// on iOS, which keeps no such history for apps.
class ScreenHistory {
  const ScreenHistory();

  static const _channel = MethodChannel('halo/screen_history');

  bool get supported => defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasAccess() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('hasAccess') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens the Usage Access page in Settings.
  Future<void> requestAccess() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      // Tests.
    }
  }

  Future<List<ScreenEvent>> events(DateTime from, DateTime to) async {
    if (!supported) return const [];
    try {
      final raw = await _channel.invokeListMethod<Object?>('events', {
        'fromMs': from.millisecondsSinceEpoch,
        'toMs': to.millisecondsSinceEpoch,
      });
      return [
        for (final item in raw ?? const [])
          if (item case [final num t, final num type])
            ScreenEvent(
              DateTime.fromMillisecondsSinceEpoch(t.toInt()),
              ScreenEventType.values[type.toInt()],
            ),
      ];
    } on MissingPluginException {
      return const [];
    }
  }
}
