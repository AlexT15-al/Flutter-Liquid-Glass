import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';

/// Every layout constant in Halo.
///
/// Nothing in a widget hardcodes a number, so a correction lands here once.
abstract final class HaloMetrics {
  // ── Navigation bar ─────────────────────────────────────────────────────────

  /// Every glass button in a navigation bar: the account button, back, `…`.
  ///
  /// Passed as `buttonSize` on every `GlassAppBar.pinned`. A bar that forgets
  /// it falls back to the package's 44 and stops matching the others.
  static const double barButtonSize = 48.0;

  /// The Edit / Done capsule. Same height as [barButtonSize] so the two read
  /// as one row of chrome; fixed width so it does not resize between labels.
  static const double editButtonWidth = 62.0;
  static const double editButtonHeight = barButtonSize;

  /// Room reserved for the bar. The shell lays the buttons out at
  /// [barButtonSize]; this only decides how far down a page's content starts.
  static const double toolbarHeight = 56.0;

  /// Glyph size inside a bar button, as a share of its diameter.
  static const double barGlyphRatio = 0.46;

  /// The back chevron. A chevron is a thin, open shape, so it needs more of
  /// the circle than a filled glyph to carry the same weight.
  static const double backGlyphRatio = 0.56;

  /// The account glyph is a filled circle, which reads smaller than a line
  /// glyph at the same size, so it gets more of the button.
  static const double accountGlyphRatio = 0.62;

  static const double barTitleSize = 17.0;
  static const double barButtonTextSize = 17.0;

  /// The iOS large title.
  static const double largeTitleSize = 34.0;
  static const double largeTitleTracking = -0.5;

  /// Where a page's content starts so it clears the status bar and the
  /// floating bar. `GlassScaffold` extends the body behind its app bar, so
  /// nothing insets the body for us.
  static double topInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + toolbarHeight + 8;

  // ── Tab bar ────────────────────────────────────────────────────────────────

  static const double tabBarHeight = 64.0;
  static const double tabBarHorizontalPadding = 20.0;
  static const double tabBarVerticalPadding = 16.0;
  static const double tabBarSpacing = 8.0;
  static const double tabIconSize = 26.0;
  static const double tabLabelSize = 10.0;
  static const double tabIconLabelSpacing = 2.0;

  /// The pill above the tab bar: a workout in progress.
  static const double accessoryHeight = 50.0;

  /// Empty space a page leaves at its bottom so its last row clears the
  /// floating tab bar, and the pill above it while a workout runs. iOS floats
  /// the bar over the home indicator; Android's three-button navigation is
  /// opaque and has to be cleared as well.
  static double bottomInset(BuildContext context) {
    final isApple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final system = isApple ? 0.0 : MediaQuery.viewPaddingOf(context).bottom;
    final accessory = ChromeAccessoryScope.isShowing(context)
        ? accessoryHeight + 8
        : 0.0;
    return tabBarHeight + 2 * tabBarVerticalPadding + 16 + system + accessory;
  }

  // ── Page ───────────────────────────────────────────────────────────────────

  /// Leading inset of page content: where a title starts.
  static const double pagePadding = 20.0;

  /// Inset of cards from the screen edges.
  static const double cardPadding = 16.0;

  /// Gap between two cards in a grid or a stack.
  static const double cardGap = 12.0;

  /// Inner padding of a card.
  static const double cardInset = 16.0;

  /// Corner radius of every solid card: a squircle, never a circular arc.
  /// 26 matches the package's own solid inset-grouped cards.
  static const double cardRadius = 26.0;

  /// A section heading above a group of cards.
  static const double sectionTitleSize = 22.0;
  static const double sectionTopGap = 28.0;
  static const double sectionTitleGap = 10.0;

  static const double separatorThickness = 0.33;

  // ── Sheets ─────────────────────────────────────────────────────────────────

  /// Top corner radius of a sheet. The sheet route already clips to the
  /// device's own screen radius, which is shallower than Apple's sheet, so the
  /// content clips again, tighter, as a squircle.
  static const double sheetTopRadius = 44.0;

  static const double sheetTopPadding = 16.0;
  static const double sheetBottomPadding = 24.0;

  /// Gap between a sheet's header row and its first content.
  static const double sheetHeaderGap = 12.0;
}

/// Whether the tab bar is carrying its accessory, so pages leave room for it.
///
/// Its own small scope rather than a dependency on the workout feature: the
/// metrics only need to know that something sits above the bar.
class ChromeAccessoryScope extends InheritedWidget {
  const ChromeAccessoryScope({
    super.key,
    required this.showing,
    required super.child,
  });

  final bool showing;

  static bool isShowing(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ChromeAccessoryScope>()
          ?.showing ??
      false;

  @override
  bool updateShouldNotify(ChromeAccessoryScope oldWidget) =>
      showing != oldWidget.showing;
}
