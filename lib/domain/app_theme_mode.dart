import 'package:flutter/widgets.dart';

/// Light, dark, or whatever the device is doing.
enum AppThemeMode {
  system(label: 'System'),
  light(label: 'Light'),
  dark(label: 'Dark');

  const AppThemeMode({required this.label});

  final String label;

  /// What the Cupertino theme pins. Null follows the device.
  Brightness? get brightness => switch (this) {
    AppThemeMode.system => null,
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
  };
}
