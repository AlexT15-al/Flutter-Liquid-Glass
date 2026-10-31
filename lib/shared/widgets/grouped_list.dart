import 'package:flutter/cupertino.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_metrics.dart';
import '../../app/theme/halo_motion.dart';
import 'halo_card.dart';

/// An inset-grouped card of rows, the iOS Settings shape: one solid squircle,
/// rows separated by hairlines that start under the text.
///
/// Drawn here rather than with the package's grouped section because some rows
/// open an editor in place beneath them, a wheel or a segmented control, and
/// that editor has to live inside the same card, between hairlines that move
/// with it.
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return HaloCard(
      padding: EdgeInsets.zero,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: HaloCard.shape),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Container(
                  height: HaloMetrics.separatorThickness,
                  margin: const EdgeInsets.only(left: 16),
                  color: HaloColors.separatorOf(context),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One row of a [GroupedCard]: a title, a value on the trailing side, and
/// whatever the row opens.
///
/// A row with [editor] toggles it open beneath itself, and its value turns the
/// accent while open: iOS's mark for a value being edited in place, as in
/// Calendar's date rows. A row with [onTap] instead shows a chevron and goes
/// somewhere.
class GroupedRow extends StatefulWidget {
  const GroupedRow({
    super.key,
    required this.title,
    this.value,
    this.leading,
    this.trailing,
    this.onTap,
    this.editor,
    this.destructive = false,
  });

  final String title;
  final String? value;
  final Widget? leading;

  /// Replaces the value text: a switch, a badge.
  final Widget? trailing;

  final VoidCallback? onTap;

  /// Opens beneath the row when it is tapped.
  final Widget? editor;

  final bool destructive;

  @override
  State<GroupedRow> createState() => _GroupedRowState();
}

class _GroupedRowState extends State<GroupedRow> {
  bool _open = false;
  bool _pressed = false;

  void _tap() {
    if (widget.editor != null) {
      setState(() => _open = !_open);
    } else {
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.editor != null || widget.onTap != null;
    final accent = HaloColors.accent.resolveFrom(context);
    final valueColor = _open ? accent : HaloColors.secondaryLabelOf(context);

    final row = AnimatedContainer(
      duration: HaloMotion.of(
        context,
        _pressed ? HaloMotion.pressInDuration : HaloMotion.pressOutDuration,
      ),
      curve: HaloMotion.pressCurve,
      color: _pressed
          ? HaloColors.labelOf(context).withValues(alpha: 0.06)
          : const Color(0x00000000),
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: widget.destructive
                    ? CupertinoColors.destructiveRed.resolveFrom(context)
                    : HaloColors.labelOf(context),
                fontSize: 17,
              ),
            ),
          ),
          if (widget.trailing != null)
            widget.trailing!
          else if (widget.value != null)
            AnimatedDefaultTextStyle(
              duration: HaloMotion.of(context, HaloMotion.controlSwapDuration),
              // Built on the ambient style: an AnimatedDefaultTextStyle replaces
              // the inherited style outright, font family included.
              style: DefaultTextStyle.of(context).style.copyWith(
                color: valueColor,
                fontSize: 17,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              child: Text(widget.value!),
            ),
          if (widget.onTap != null &&
              widget.editor == null &&
              widget.trailing == null) ...[
            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 15,
              color: HaloColors.tertiaryLabelOf(context),
            ),
          ],
        ],
      ),
    );

    return Column(
      children: [
        if (interactive)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: row,
          )
        else
          row,
        // Grows and shrinks rather than appearing: the rows below slide to
        // make room, so the editor reads as unfolding out of its row.
        AnimatedSize(
          duration: HaloMotion.of(context, HaloMotion.standardDuration),
          curve: HaloMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: _open && widget.editor != null
              ? widget.editor!
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The uppercase caption over a [GroupedCard], and the footnote under one.
class GroupCaption extends StatelessWidget {
  const GroupCaption(this.text, {super.key, this.footer = false});

  final String text;
  final bool footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: footer
          ? const EdgeInsets.fromLTRB(16, 8, 16, 0)
          : const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        footer ? text : text.toUpperCase(),
        style: TextStyle(
          color: HaloColors.secondaryLabelOf(context),
          fontSize: 13,
          fontWeight: footer ? FontWeight.w400 : FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

/// A wheel picker sized for a row's editor.
class RowWheel extends StatelessWidget {
  const RowWheel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(height: 180, child: child);
}
