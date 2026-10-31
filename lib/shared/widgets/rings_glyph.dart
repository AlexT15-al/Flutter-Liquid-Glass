import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Three concentric rings, the Today tab's glyph.
///
/// SF Symbols has the Fitness rings; Cupertino icons do not, so this draws
/// them. It behaves like an [Icon]: colour and size come from the ambient
/// [IconTheme], which is how the tab bar tints the selected tab, so it needs
/// no special case anywhere it is used.
///
/// Drawn as complete, heavy rings. A tab glyph is always the filled variant,
/// and for rings "filled" means solid strokes with no gaps or open ends.
class RingsGlyph extends StatelessWidget {
  const RingsGlyph({super.key, this.size});

  /// Null takes the size from the [IconTheme], as [Icon] does.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final extent = size ?? theme.size ?? 24.0;
    final color = theme.color ?? const Color(0xFF000000);

    return SizedBox.square(
      dimension: extent,
      child: CustomPaint(painter: _RingsPainter(color)),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final extent = math.min(size.width, size.height);
    final centre = size.center(Offset.zero);

    // Three strokes and two gaps across the radius, with the glyph inset a
    // touch so it optically matches the padding built into SF glyphs.
    final radius = extent * 0.46;
    final stroke = radius * 0.24;
    final gap = radius * 0.11;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;

    for (var i = 0; i < 3; i++) {
      final r = radius - stroke / 2 - i * (stroke + gap);
      canvas.drawCircle(centre, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) => oldDelegate.color != color;
}
