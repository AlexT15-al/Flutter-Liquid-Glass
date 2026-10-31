import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../app/theme/halo_colors.dart';
import '../../../../shared/widgets/halo_card.dart';

/// Today's readiness: how much the body has in it, from sleep, recent load
/// and resting heart rate.
///
/// Readiness is built from sleep and resting heart rate, which arrive with the
/// Sleep tab and the camera heart-rate reading. Until there is enough of both,
/// the card says what it needs rather than showing a number it cannot
/// justify.
class ReadinessCard extends StatelessWidget {
  const ReadinessCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);

    return HaloCard(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CustomPaint(
              painter: _GaugePainter(track: HaloColors.ringTrack(accent)),
              child: Center(
                child: Text(
                  '—',
                  style: TextStyle(
                    color: HaloColors.secondaryLabelOf(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.bolt_fill, size: 15, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      'Readiness',
                      style: TextStyle(
                        color: accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Not Enough Data',
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track three nights of sleep to see how ready you are each '
                  'morning.',
                  style: TextStyle(
                    color: HaloColors.secondaryLabelOf(context),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A three-quarter gauge track, open at the bottom.
class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.track});

  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = track,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) => oldDelegate.track != track;
}
