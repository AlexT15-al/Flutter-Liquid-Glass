import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The switch for haptic feedback, everywhere in the app.
///
/// Haptics come from many places: Halo's own controls, the glass widgets,
/// Cupertino's switches and pickers. All of them end in the same platform
/// message, so the gate sits there, on the binding's messenger, and turning
/// haptics off reaches every one of them, including those the app never sees.
abstract final class Haptics {
  static bool enabled = true;
}

/// The app's binding: Flutter's own, with the haptics gate on its messenger.
class HaloBinding extends WidgetsFlutterBinding {
  static bool _created = false;

  /// Creates the binding, once. Call it first thing in `main`, before anything
  /// else can create Flutter's default one.
  static WidgetsBinding ensureInitialized() {
    if (!_created) {
      _created = true;
      HaloBinding();
    }
    return WidgetsBinding.instance;
  }

  @override
  BinaryMessenger createBinaryMessenger() =>
      HapticsGate(super.createBinaryMessenger());
}

/// Passes every platform message on, except haptics while they are off.
class HapticsGate implements BinaryMessenger {
  HapticsGate(this._inner);

  final BinaryMessenger _inner;

  static const _codec = JSONMethodCodec();
  static final String _platform = SystemChannels.platform.name;

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    if (!Haptics.enabled && channel == _platform && message != null) {
      try {
        if (_codec.decodeMethodCall(message).method ==
            'HapticFeedback.vibrate') {
          return Future.value(_codec.encodeSuccessEnvelope(null));
        }
      } on Object {
        // Not a method call: pass it on untouched.
      }
    }
    return _inner.send(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) =>
      _inner.setMessageHandler(channel, handler);

  @override
  // ignore: deprecated_member_use
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) =>
      // ignore: deprecated_member_use
      _inner.handlePlatformMessage(channel, data, callback);
}
