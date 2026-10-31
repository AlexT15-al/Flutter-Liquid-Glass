import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_glass.dart';
import '../../app/theme/halo_metrics.dart';

/// Presents a sheet the way iOS 26 presents one, and the way Clock does.
///
/// Flutter's own `showCupertinoSheet`: an opaque card that slides up from the
/// bottom edge and drags down to dismiss. The page behind stays where it is.
/// iOS 26 dropped the old zoom-out, where the page shrank back behind the
/// sheet; here the page only dims (see `HaloPage`), which is what keeps the
/// sheet distinct in light mode, where the two share a colour.
///
/// The sheet's top stops at the status bar. A custom top gap is also what
/// turns the route's zoom-out off: Flutter only plays it for its own default.
///
/// [nested] gives the sheet its own Navigator, so a page pushed from inside it
/// slides across the sheet rather than covering it.
Future<T?> showHaloSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, ScrollController controller)
      builder,
  bool nested = false,
}) {
  final media = MediaQuery.of(context);
  return showCupertinoSheet<T>(
    context: context,
    topGap: (media.padding.top / media.size.height).clamp(0.0, 0.9),
    useNestedNavigation: nested,
    scrollableBuilder: builder,
  );
}

/// The body of a sheet: the surface, the rounded top, the header, and content
/// that scrolls on the route's own controller.
///
/// The content must scroll on [controller], the one the sheet route hands its
/// builder. That is how the route knows a downward drag started at the top of
/// the content and should pull the sheet down rather than scroll.
class HaloSheet extends StatelessWidget {
  const HaloSheet({
    super.key,
    required this.controller,
    required this.header,
    required this.children,
  });

  final ScrollController controller;
  final HaloSheetHeader header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // The route clips to the device's screen radius, shallower than Apple's
    // sheet. Clipping again, tighter and as a squircle, is the only way to
    // round it further; the sliver between the two clips shows the page
    // scaled back behind, which is what belongs there.
    return ClipRSuperellipse(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(HaloMetrics.sheetTopRadius),
      ),
      child: ColoredBox(
        color: HaloColors.sheet.resolveFrom(context),
        child: SafeArea(
          // The route already stops at the status bar; consuming the top inset
          // again would leave a second gap above the header.
          top: false,
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(
              HaloMetrics.cardPadding,
              HaloMetrics.sheetTopPadding,
              HaloMetrics.cardPadding,
              HaloMetrics.sheetBottomPadding,
            ),
            children: [
              header,
              const SizedBox(height: HaloMetrics.sheetHeaderGap),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// A sheet's header: an optional button on each side and the title centred on
/// the sheet.
///
/// A [Stack] rather than a `Row`: the two buttons can differ in width, and a
/// title centred between them would sit off the sheet's centre.
class HaloSheetHeader extends StatelessWidget {
  const HaloSheetHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HaloMetrics.barButtonSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            // Keeps a long title clear of the buttons on either side.
            padding: const EdgeInsets.symmetric(
              horizontal: HaloMetrics.barButtonSize + 8,
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: HaloColors.labelOf(context),
                fontSize: HaloMetrics.barTitleSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (leading != null)
            Align(alignment: Alignment.centerLeft, child: leading),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}

/// A 48pt glass circle in a sheet's header: ✕, back, and the like.
///
/// Its own layer, always: a sheet route has no glass layer above it to resolve
/// a material from, and a glass widget without one throws.
class SheetButton extends StatelessWidget {
  const SheetButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// Read by the screen reader: the button's only name.
  final String label;

  final VoidCallback onTap;

  /// ✕, which dismisses the sheet without keeping anything.
  factory SheetButton.close(BuildContext context, {VoidCallback? onTap}) =>
      SheetButton(
        icon: CupertinoIcons.xmark,
        label: 'Close',
        onTap: onTap ?? () => Navigator.of(context, rootNavigator: true).pop(),
      );

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      icon: Icon(icon),
      onTap: onTap,
      label: label,
      width: HaloMetrics.barButtonSize,
      height: HaloMetrics.barButtonSize,
      iconSize: HaloMetrics.barButtonSize * HaloMetrics.barGlyphRatio,
      iconColor: HaloColors.labelOf(context),
      settings: HaloGlass.of(context),
      quality: HaloGlass.quality,
      useOwnLayer: true,
    );
  }
}

/// The confirming button in a sheet's header: a glass circle tinted with the
/// accent, carrying a tick.
///
/// The same glass button as its neighbour, only coloured, so it presses and
/// catches the light the same way. Null [onTap] dims it and stops it
/// answering, for a sheet that has nothing to confirm yet.
class SheetConfirmButton extends StatelessWidget {
  const SheetConfirmButton({
    super.key,
    required this.onTap,
    this.icon = CupertinoIcons.checkmark_alt,
    this.label = 'Done',
  });

  final VoidCallback? onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: GlassButton(
        icon: Icon(icon),
        onTap: onTap ?? () {},
        enabled: enabled,
        label: label,
        width: HaloMetrics.barButtonSize,
        height: HaloMetrics.barButtonSize,
        // Large and heavy, as the iOS sheet tick is: at the size of the
        // other header glyphs it reads as a mark rather than as the action.
        iconSize: HaloMetrics.barButtonSize * 0.62,
        iconColor: HaloColors.onAccent.resolveFrom(context),
        settings: HaloGlass.tinted(HaloColors.accent.resolveFrom(context)),
        quality: HaloGlass.quality,
        useOwnLayer: true,
      ),
    );
  }
}

/// The uppercase caption over a group of rows in a sheet or a settings list.
class SectionCaption extends StatelessWidget {
  const SectionCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: HaloColors.secondaryLabelOf(context),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
