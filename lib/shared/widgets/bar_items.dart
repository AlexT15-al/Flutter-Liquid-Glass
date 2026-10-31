import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_glass.dart';
import '../../app/theme/halo_metrics.dart';

/// The ids bar items are matched by across routes.
///
/// `GlassBarItem.id` mirrors `UIBarButtonItem.identifier`: two items with the
/// same id on two routes are treated as the same item during a push, so they
/// hold their place while the rest of the cluster morphs around them. Left
/// null, items are matched by position, which breaks as soon as one screen has
/// a button the other does not.
abstract final class BarItemIds {
  static const back = 'back';
  static const account = 'account';
  static const edit = 'edit';
}

/// One row of a pull-down menu, styled once.
///
/// The glyph goes in bare: `GlassMenuItem` wraps it in an `IconTheme` from its
/// own `iconColor`, and colouring the `Icon` here would override that and lose
/// the disabled dimming. The title style is passed explicitly because a label
/// colour is exactly what silently falls back to a default otherwise.
GlassMenuItem haloMenuItem(
  BuildContext context, {
  required String title,
  required IconData icon,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  final label = HaloColors.labelOf(context);
  return GlassMenuItem(
    title: title,
    icon: Icon(icon),
    iconColor: label,
    titleStyle: TextStyle(color: label, fontSize: HaloMetrics.barTitleSize),
    isDestructive: isDestructive,
    onTap: onTap,
  );
}

/// Every pull-down menu in the app, with one material and one behaviour.
///
/// `enableContinuousSwipe` is the iOS 26 pull-down: press and the menu opens
/// under the finger, slide onto an item, release to choose it, all one
/// gesture; release without moving and it stays open for a tap. It opens from
/// the raw pointer-down, so the trigger must not also toggle the menu: its tap
/// would arrive on release and close the menu the press just opened. That is
/// why [triggerBuilder] is handed nothing to call.
class HaloMenu extends StatelessWidget {
  const HaloMenu({
    super.key,
    required this.items,
    required this.trigger,
    this.width = 220,
    this.alignment = GlassMenuAlignment.topRight,
  });

  final List<Widget> items;
  final Widget trigger;
  final double width;
  final GlassMenuAlignment alignment;

  @override
  Widget build(BuildContext context) {
    const inset = HaloMetrics.cardPadding;
    return GlassMenu(
      menuWidth: width,
      menuAlignment: alignment,
      autoAdjustToScreen: true,
      // The bottom inset is the floating tab bar's height, so a menu opened
      // low on a page is nudged up above the bar instead of under it.
      menuPadding: EdgeInsets.fromLTRB(
        inset,
        inset,
        inset,
        HaloMetrics.bottomInset(context),
      ),
      settings: HaloGlass.of(context),
      // Named here: bars wrap their contents in an isolation scope with its
      // own default tier, which a menu opened from a bar would otherwise take.
      quality: HaloGlass.quality,
      selectionColor: HaloColors.labelOf(context).withValues(alpha: 0.12),
      enableContinuousSwipe: true,
      items: items,
      triggerBuilder: (context, _) => trigger,
    );
  }
}

/// The account button on the tab roots: a 48pt glass circle that opens its
/// menu under the finger and lets it slide straight onto an item.
///
/// A custom item with its own glass rather than `GlassBarItem.menu`: the
/// package's bar menu has no continuous swipe, and a custom item keeps our
/// material and tier while still taking part in the cross-route morph.
GlassBarItem accountBarItem(
  BuildContext context, {
  required Widget glyph,
  required VoidCallback onProfile,
  required VoidCallback onGoals,
  required VoidCallback onAwards,
  required VoidCallback onSettings,
}) {
  return GlassBarItem.custom(
    id: BarItemIds.account,
    label: 'Account',
    background: GlassBarItemBackground.own,
    child: HaloMenu(
      items: [
        haloMenuItem(
          context,
          title: 'Profile',
          icon: CupertinoIcons.person_fill,
          onTap: onProfile,
        ),
        haloMenuItem(
          context,
          title: 'Goals',
          icon: CupertinoIcons.scope,
          onTap: onGoals,
        ),
        haloMenuItem(
          context,
          title: 'Awards',
          icon: CupertinoIcons.rosette,
          onTap: onAwards,
        ),
        const GlassMenuDivider(),
        haloMenuItem(
          context,
          title: 'Settings',
          icon: CupertinoIcons.gear_alt_fill,
          onTap: onSettings,
        ),
      ],
      trigger: BarCircleButton(label: 'Account', glyph: glyph),
    ),
  );
}

/// A 48pt glass circle for a custom bar item.
///
/// Sized from the height the bar lays it out at, not from a constant: a pinned
/// item is held to the cluster's height but not its width, and a fixed pair of
/// numbers came out as an ellipse in Music. Squaring the height keeps it round.
///
/// Its tap is inert. It is a menu trigger: the menu opens from the pointer.
class BarCircleButton extends StatelessWidget {
  const BarCircleButton({super.key, required this.label, required this.glyph});

  final String label;
  final Widget glyph;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : HaloMetrics.barButtonSize;
        return GlassButton.custom(
          onTap: () {},
          label: label,
          width: diameter,
          height: diameter,
          shape: const LiquidOval(),
          settings: HaloGlass.of(context),
          quality: HaloGlass.quality,
          useOwnLayer: true,
          child: Center(child: glyph),
        );
      },
    );
  }
}

/// The Edit / Done capsule: 62 × 48, glass, fixed width so it does not resize
/// when its label changes.
///
/// Its own layer, always. Without one a glass widget resolves its material
/// from the nearest ancestor glass layer, and throws where there is none,
/// which is any route presented outside a scaffold.
class EditButton extends StatelessWidget {
  const EditButton({
    super.key,
    required this.editing,
    required this.onTap,
  });

  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = editing ? 'Done' : 'Edit';
    return GlassButton.custom(
      onTap: onTap,
      label: label,
      width: HaloMetrics.editButtonWidth,
      height: HaloMetrics.editButtonHeight,
      shape: const LiquidRoundedRectangle(
        borderRadius: HaloMetrics.editButtonHeight / 2,
      ),
      settings: HaloGlass.of(context),
      quality: HaloGlass.quality,
      useOwnLayer: true,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            // Done is the confirming action, so it takes the accent and the
            // weight; Edit is a plain entry point.
            color: editing
                ? HaloColors.accent.resolveFrom(context)
                : HaloColors.labelOf(context),
            fontSize: HaloMetrics.barButtonTextSize,
            fontWeight: editing ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// [EditButton] as a pinned bar item, matched across routes by its id.
GlassBarItem editBarItem({
  required bool editing,
  required VoidCallback onTap,
}) {
  return GlassBarItem.custom(
    id: BarItemIds.edit,
    label: editing ? 'Done' : 'Edit',
    background: GlassBarItemBackground.own,
    child: EditButton(editing: editing, onTap: onTap),
  );
}
