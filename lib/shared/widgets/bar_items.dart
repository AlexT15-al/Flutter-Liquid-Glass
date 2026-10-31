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

/// The account button on the tab roots: a 48pt glass circle that morphs into
/// its menu.
///
/// `GlassBarItem.menu` with a `separate` background: the whole circle becomes
/// the pull-down, the iOS 26 way. `separate` gives it its own circular shell
/// at the bar's 48pt button size; a lone `shared` item would instead draw at
/// the capsule's height and come out 2pt larger than everything beside it.
GlassBarItem accountBarItem(
  BuildContext context, {
  required VoidCallback onProfile,
  required VoidCallback onGoals,
  required VoidCallback onAwards,
  required VoidCallback onSettings,
}) {
  return GlassBarItem.menu(
    id: BarItemIds.account,
    label: 'Account',
    background: GlassBarItemBackground.separate,
    icon: const Icon(
      CupertinoIcons.person_crop_circle_fill,
      size: HaloMetrics.barButtonSize * HaloMetrics.accountGlyphRatio,
    ),
    menuSettings: HaloGlass.of(context),
    menuWidth: 220,
    menuItems: [
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
  );
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
