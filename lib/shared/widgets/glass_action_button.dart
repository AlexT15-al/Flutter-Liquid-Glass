import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_glass.dart';

/// The one primary action of a screen, as a full-width capsule of tinted
/// liquid glass: Start.
///
/// Glass rather than a flat fill, so it presses, stretches and catches the
/// light like every other control the user drives. Tinted with the accent and
/// composited clear, so the lime stays lime over a dark sheet.
class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 56,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ink = HaloColors.onAccent.resolveFrom(context);
    return GlassButton.custom(
      onTap: onTap,
      label: label,
      width: double.infinity,
      height: height,
      shape: LiquidRoundedRectangle(borderRadius: height / 2),
      settings: HaloGlass.tinted(HaloColors.accent.resolveFrom(context)),
      quality: HaloGlass.quality,
      // A sheet or a layer has no glass layer above it to share.
      useOwnLayer: true,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: ink),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: ink,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
