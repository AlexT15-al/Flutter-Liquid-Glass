import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../app/theme/halo_colors.dart';
import '../../../../app/theme/halo_motion.dart';

/// A night's score as a ring that fills to it, with the number inside.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 96,
    this.stroke = 10,
  });

  final int score;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final color = HaloColors.sleep.resolveFrom(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: HaloMotion.of(context, const Duration(milliseconds: 900)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(value: value, color: color, stroke: stroke),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                color: HaloColors.labelOf(context),
                fontSize: size * 0.34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.stroke,
  });

  final double value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = HaloColors.ringTrack(color),
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.stroke != stroke;
}
