import 'package:flutter/services.dart';

/// The home screen widget: the app hands it today's numbers, and the widget
/// draws from them until the next update.
class HomeWidget {
  const HomeWidget();

  static const _channel = MethodChannel('halo/widget');

  Future<void> update(Map<String, num> values) async {
    try {
      await _channel.invokeMethod<void>('update', values);
    } on MissingPluginException {
      // Tests, and platforms without widgets.
    } on PlatformException {
      // A widget that misses one update catches up on the next.
    }
  }
}
