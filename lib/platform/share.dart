import 'package:flutter/services.dart';

/// The system share sheet, for an image.
class SystemShare {
  const SystemShare();

  static const _channel = MethodChannel('halo/share');

  Future<void> image(Uint8List png, {required String name, String? text}) =>
      _channel.invokeMethod<bool>('image', {
        'png': png,
        'name': name,
        'text': ?text,
      });
}
