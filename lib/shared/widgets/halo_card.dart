import 'package:flutter/cupertino.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_metrics.dart';
import '../../app/theme/halo_motion.dart';

/// A solid squircle card: the surface every piece of content sits on.
///
/// Not glass. Glass is for chrome that floats over moving content; a card is
/// content, sitting flat on a still page, where a shader pass per card buys
/// nothing.
///
/// Tappable cards answer the finger the way iOS does: on pointer-down, not on
/// release, with a shallow sink and a faint wash, both springing back on
/// release. A card with no [onTap] does neither, so nothing promises an action
/// it cannot take.
class HaloCard extends StatefulWidget {
  const HaloCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(HaloMetrics.cardInset),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Defaults to [HaloColors.card].
  final Color? color;

  /// The card's outline, shared by its fill and its clip so the two can never
  /// disagree by a pixel at the corners.
  static final ShapeBorder shape = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(HaloMetrics.cardRadius),
  );

  @override
  State<HaloCard> createState() => _HaloCardState();
}

class _HaloCardState extends State<HaloCard> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final duration = HaloMotion.of(
      context,
      _pressed ? HaloMotion.pressInDuration : HaloMotion.pressOutDuration,
    );

    final card = DecoratedBox(
      decoration: ShapeDecoration(
        shape: HaloCard.shape,
        color: widget.color ?? HaloColors.card.resolveFrom(context),
      ),
      child: Stack(
        children: [
          Padding(padding: widget.padding, child: widget.child),
          if (interactive)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: duration,
                  curve: HaloMotion.pressCurve,
                  decoration: ShapeDecoration(
                    shape: HaloCard.shape,
                    color: HaloColors.labelOf(
                      context,
                    ).withValues(alpha: _pressed ? 0.06 : 0),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!interactive) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      // Down, up and cancel: cancel is what fires when the touch turns into a
      // scroll, and without it the card would stay sunk under a flick.
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? HaloMotion.pressScale : 1,
        duration: duration,
        curve: HaloMotion.pressCurve,
        child: card,
      ),
    );
  }
}

/// A solid capsule button for use inside a card.
///
/// Inside a card a glass button would be glass on a content surface, which the
/// glass rules forbid; the iOS answer is a filled capsule.
class FilledCapsuleButton extends StatefulWidget {
  const FilledCapsuleButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 40,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  State<FilledCapsuleButton> createState() => _FilledCapsuleButtonState();
}

class _FilledCapsuleButtonState extends State<FilledCapsuleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final duration = HaloMotion.of(
      context,
      _pressed ? HaloMotion.pressInDuration : HaloMotion.pressOutDuration,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.7 : 1,
        duration: duration,
        curve: HaloMotion.pressCurve,
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: HaloColors.accent.resolveFrom(context),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: HaloColors.onAccent.resolveFrom(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
