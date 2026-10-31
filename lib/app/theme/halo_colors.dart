import 'package:flutter/cupertino.dart';

/// Every colour in Halo.
///
/// Nothing in a widget names a hex value. Surfaces and the accent are
/// [CupertinoDynamicColor]s so one token covers both appearances; resolve them
/// with `.resolveFrom(context)` at the point of use.
abstract final class HaloColors {
  // ── Surfaces ───────────────────────────────────────────────────────────────

  /// The page behind every screen.
  ///
  /// Pure black in dark mode, the way Fitness draws it, so the rings and the
  /// accent carry the screen. Light mode is systemGroupedBackground: pure white
  /// would leave the solid cards nothing to sit on.
  static const background = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7),
    darkColor: Color(0xFF000000),
  );

  /// A solid card on [background]: secondarySystemGroupedBackground.
  static const card = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF1C1C1E),
  );

  /// A card that sits inside a sheet or on another card, one step up.
  static const cardElevated = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF2C2C2E),
  );

  /// The fill behind a control inside a card: tertiarySystemFill.
  static const fill = CupertinoDynamicColor.withBrightness(
    color: Color(0x1F767680),
    darkColor: Color(0x3D767680),
  );

  // ── Accent ─────────────────────────────────────────────────────────────────

  /// The Fitness lime, the app's only accent.
  ///
  /// `#A6FF00` reads at 17:1 on black, but at 1.2:1 on white it is invisible,
  /// so the light appearance takes a deeper lime of the same hue that clears
  /// 4:1 on white and 3.6:1 on the grouped background.
  static const accent = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF4A8F00),
    darkColor: Color(0xFFA6FF00),
  );

  /// Text and glyphs drawn on an [accent] fill: black on the bright lime,
  /// white on the deep one.
  static const onAccent = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF000000),
  );

  // ── Activity rings ─────────────────────────────────────────────────────────
  //
  // Fixed in both appearances: the rings are graphics, not text, and they are
  // the same rings whether the page behind them is black or grey.

  static const move = Color(0xFFFA114F);
  static const exercise = Color(0xFFA6FF00);
  static const activeHours = Color(0xFF1EEAEF);

  /// The unfilled track behind a ring: its own colour, faded.
  static Color ringTrack(Color ring) => ring.withValues(alpha: 0.22);

  // ── Health categories ──────────────────────────────────────────────────────
  //
  // The iOS system colours Health uses for its categories, light then dark.

  static const activity = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF9500),
    darkColor: Color(0xFFFF9F0A),
  );
  static const body = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFAF52DE),
    darkColor: Color(0xFFBF5AF2),
  );
  static const heart = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF2D55),
    darkColor: Color(0xFFFF375F),
  );
  static const vitals = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF3B30),
    darkColor: Color(0xFFFF453A),
  );
  static const nutrition = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF34C759),
    darkColor: Color(0xFF30D158),
  );
  static const hydration = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF007AFF),
    darkColor: Color(0xFF0A84FF),
  );
  static const sleep = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF5856D6),
    darkColor: Color(0xFF5E5CE6),
  );
  static const mindfulness = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF32ADE6),
    darkColor: Color(0xFF64D2FF),
  );
  static const cycle = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF6482),
    darkColor: Color(0xFFFF7A94),
  );
  static const medications = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF00C7BE),
    darkColor: Color(0xFF63E6E2),
  );

  // ── Text ───────────────────────────────────────────────────────────────────

  static Color labelOf(BuildContext context) =>
      CupertinoColors.label.resolveFrom(context);

  static Color secondaryLabelOf(BuildContext context) =>
      CupertinoColors.secondaryLabel.resolveFrom(context);

  static Color tertiaryLabelOf(BuildContext context) =>
      CupertinoColors.tertiaryLabel.resolveFrom(context);

  // ── Hairlines ──────────────────────────────────────────────────────────────

  /// The separator between rows: the label colour at 10%, so it inverts with
  /// the theme without a second token.
  static Color separatorOf(BuildContext context) =>
      labelOf(context).withValues(alpha: 0.10);
}
