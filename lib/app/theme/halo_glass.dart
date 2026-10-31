import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Halo's glass: the package's iOS 27 `glassEffect(.regular)` material,
/// rendered at premium everywhere.
///
/// The app-wide theme is `GlassThemeData.ios27()`, whose variants already
/// carry `GlassQuality.premium`, so most glass inherits both from there and
/// passes nothing. These accessors exist for the places that have to name the
/// material or the tier explicitly:
///
/// - `GlassAppBar.pinned(buttonSettings:)`, whose hoisted buttons are drawn by
///   the navigation shell above every route and would otherwise fall back to
///   the shell's own defaults.
/// - Bars and menus, which sit inside a `GlassIsolationScope`. Naming the tier
///   on the widget is the one resolution step nothing above can override.
///
/// The settings are the package's `const` objects, so every caller gets the
/// same instance. Glass widgets compare settings by identity to decide whether
/// to redo their shader work, and a fresh object per build would re-render for
/// nothing.
abstract final class HaloGlass {
  /// Premium, always: the full multi-pass material with the iOS 27 frost and
  /// rim, never the approximation.
  static const quality = GlassQuality.premium;

  /// The theme for `LiquidGlassWidgets.wrap`.
  static const theme = GlassThemeData.ios27();

  /// The app's brightness: the Cupertino theme's pin, or the platform's when
  /// the theme follows the system.
  static Brightness brightnessOf(BuildContext context) =>
      CupertinoTheme.of(context).brightness ??
      MediaQuery.platformBrightnessOf(context);

  /// The iOS 27 material for the current appearance.
  static LiquidGlassSettings of(BuildContext context) =>
      brightnessOf(context) == Brightness.dark
          ? LiquidGlassSettings.ios27Dark
          : LiquidGlassSettings.ios27Light;
}
