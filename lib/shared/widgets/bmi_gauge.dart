import 'package:flutter/cupertino.dart';

import '../../app/theme/halo_colors.dart';
import '../../domain/body_profile.dart';
import '../format.dart';

/// The colour of each band of body mass index.
Color bmiColor(BuildContext context, BmiCategory category) =>
    switch (category) {
      BmiCategory.underweight => CupertinoColors.systemTeal,
      BmiCategory.healthy => HaloColors.accent,
      BmiCategory.overweight => CupertinoColors.systemOrange,
      BmiCategory.obese => CupertinoColors.systemRed,
    }.resolveFrom(context);

/// Body mass index as a row of a grouped card: the number and its band,
/// and under it the four bands on one scale with a dot where the user is
/// and, with a target, a ring where they are going.
class BmiRow extends StatelessWidget {
  const BmiRow({super.key, required this.bmi, this.target});

  final double bmi;

  /// At the target weight, if there is one.
  final double? target;

  @override
  Widget build(BuildContext context) {
    final category = Bmi.category(bmi);
    final secondary = HaloColors.secondaryLabelOf(context);
    return Semantics(
      label: 'BMI ${bmi.toStringAsFixed(1)}, ${category.title}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'BMI',
                    style: TextStyle(
                      color: HaloColors.labelOf(context),
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  ' · ${category.title}',
                  style: TextStyle(
                    color: bmiColor(context, category),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BmiGauge(bmi: bmi, target: target),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final (label, flex) in const [
                  ('', 35),
                  ('18.5', 65),
                  ('25', 50),
                  ('30', 100),
                ])
                  Expanded(
                    flex: flex,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
            if (target != null) ...[
              const SizedBox(height: 4),
              Text(
                'At your target: ${target!.toStringAsFixed(1)} · '
                '${Bmi.category(target!).title}',
                style: TextStyle(color: secondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The four bands from 15 to 40 on one bar.
class BmiGauge extends StatelessWidget {
  const BmiGauge({super.key, required this.bmi, this.target});

  static const double low = 15;
  static const double high = 40;

  final double bmi;
  final double? target;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: CustomPaint(
        painter: _GaugePainter(
          bmi: bmi,
          target: target,
          colors: [for (final c in BmiCategory.values) bmiColor(context, c)],
          ring: HaloColors.labelOf(context),
          background: HaloColors.card.resolveFrom(context),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.bmi,
    required this.target,
    required this.colors,
    required this.ring,
    required this.background,
  });

  final double bmi;
  final double? target;
  final List<Color> colors;
  final Color ring;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    const bar = 6.0;
    final y = size.height / 2;
    double x(double v) =>
        ((v - BmiGauge.low) / (BmiGauge.high - BmiGauge.low)).clamp(0.0, 1.0) *
        size.width;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y - bar / 2, size.width, bar),
      const Radius.circular(bar / 2),
    );
    canvas.save();
    canvas.clipRRect(track);
    for (var i = 0; i < BmiCategory.values.length; i++) {
      final c = BmiCategory.values[i];
      final from = x(c.from.clamp(BmiGauge.low, BmiGauge.high));
      final to = x(c.to.clamp(BmiGauge.low, BmiGauge.high));
      canvas.drawRect(
        Rect.fromLTRB(from, y - bar / 2, to, y + bar / 2),
        Paint()..color = colors[i].withValues(alpha: 0.85),
      );
      // A hairline between bands.
      if (i > 0) {
        canvas.drawRect(
          Rect.fromLTWH(from - 1, y - bar / 2, 2, bar),
          Paint()..color = background,
        );
      }
    }
    canvas.restore();

    final t = target;
    if (t != null) {
      canvas.drawCircle(
        Offset(x(t), y),
        5.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ring,
      );
    }
    final at = Offset(x(bmi), y);
    canvas.drawCircle(at, 7, Paint()..color = background);
    canvas.drawCircle(at, 5, Paint()..color = ring);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.bmi != bmi ||
      old.target != target ||
      old.ring != ring ||
      old.background != background;
}

/// "59–79 kg"
String healthyRangeText(double heightCm) {
  final (from, to) = Bmi.healthyRange(heightCm);
  return '${Format.integer(from)}–${Format.integer(to)} kg';
}
