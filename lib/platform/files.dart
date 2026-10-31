import 'package:flutter/services.dart';

/// The system's file pickers, for exporting and importing data.
class SystemFiles {
  const SystemFiles();

  static const _channel = MethodChannel('halo/files');

  /// Writes [files] into a new [folder] wherever the user picks. False if
  /// they cancelled.
  Future<bool> export(String folder, Map<String, String> files) async =>
      await _channel.invokeMethod<bool>('export', {
        'folder': folder,
        'files': files,
      }) ??
      false;

  /// Files the user picks, by name; null if they cancelled.
  Future<Map<String, String>?> import() async {
    final picked = await _channel.invokeMapMethod<String, String>('import');
    return picked;
  }
}
