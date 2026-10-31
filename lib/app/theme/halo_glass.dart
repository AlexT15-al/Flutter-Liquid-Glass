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

  static final _tabBar = <Brightness, LiquidGlassSettings>{};

  /// The floating tab bar: the Music app's tab bar material, value for value.
  ///
  /// The one surface that does not use the iOS 27 preset. A thick,
  /// barely-blurred glass with a medium specular, so the long capsule catches
  /// the light along its length, and a lower alpha so the content scrolling
  /// under it stays readable.
  ///
  /// Cached per brightness: glass widgets compare settings by identity, and a
  /// fresh object per build would redo the shader work for nothing.
  static LiquidGlassSettings tabBar(BuildContext context) {
    final brightness = brightnessOf(context);
    return _tabBar.putIfAbsent(brightness, () {
      final isDark = brightness == Brightness.dark;
      return LiquidGlassSettings(
        glassColor: isDark ? const Color(0xAA1C1C1E) : const Color(0xAAF2F2F7),
        thickness: 30,
        blur: 2,
        chromaticAberration: 0.01,
        lightAngle: GlassDefaults.lightAngle,
        lightIntensity: 0.2,
        ambientStrength: 0,
        refractiveIndex: 1.2,
        fresnelStrength: 0,
        saturation: 1.2,
        specularSharpness: GlassSpecularSharpness.medium,
      );
    });
  }

  static final _tinted = <int, LiquidGlassSettings>{};

  /// The iOS 27 material carrying a colour: the confirm button on a sheet.
  ///
  /// Still glass, so it presses, stretches and catches the light like the
  /// plain buttons beside it. Without the frost, which would wash the colour
  /// out, and with `bodyMode: clear`: the default mode keeps the backdrop's
  /// brightness and takes only the hue, which over a dark sheet turns the lime
  /// to olive. `clear` composites the colour as it is.
  ///
  /// Cached by colour for the identity reason above.
  static LiquidGlassSettings tinted(Color tint) => _tinted.putIfAbsent(
    tint.toARGB32(),
    () => LiquidGlassSettings(
      glassColor: tint,
      bodyMode: GlassBodyMode.clear,
      thickness: 32,
      blur: 0.6,
      refractiveIndex: 1.24,
      lensModel: GlassLensModel.paraxial,
      saturation: 1.2,
      lightIntensity: 0.2,
      fresnelStrength: 0,
      chromaticAberration: 0,
      edgeAbsorption: 0.035,
      rimLight: 1,
    ),
  );

  /// The iOS 27 material for the current appearance.
  static LiquidGlassSettings of(BuildContext context) =>
      brightnessOf(context) == Brightness.dark
      ? LiquidGlassSettings.ios27Dark
      : LiquidGlassSettings.ios27Light;
}
