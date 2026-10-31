import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../app/theme/halo_colors.dart';
import '../../../../shared/format.dart';

/// A day's 24 hours as bars, with the hour marks beneath and the peak marked
/// by a faint rule along the top: the hourly chart under each ring in Fitness.
class HourlyChart extends StatelessWidget {
  const HourlyChart({
    super.key,
    required this.values,
    required this.color,
    this.upToHour,
    this.height = 84,
  });

  final List<double> values;
  final Color color;

  /// Hours after this one have not happened yet and draw nothing.
  final int? upToHour;

  final double height;

  @override
  Widget build(BuildContext context) {
    final peak = values.fold<double>(0, math.max);
    final secondary = HaloColors.secondaryLabelOf(context);
    final labelStyle = TextStyle(
      color: secondary,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HourlyPainter(
                    values: values,
                    color: color,
                    track: HaloColors.fill.resolveFrom(context),
                    rule: HaloColors.separatorOf(context),
                    upToHour: upToHour,
                  ),
                ),
              ),
              if (peak > 0)
                Positioned(
                  right: 0,
                  top: -1,
                  child: Text(Format.integer(peak), style: labelStyle),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final hour in const ['00:00', '06:00', '12:00', '18:00'])
              Expanded(child: Text(hour, style: labelStyle)),
          ],
        ),
      ],
    );
  }
}

class _HourlyPainter extends CustomPainter {
  _HourlyPainter({
    required this.values,
    required this.color,
    required this.track,
    required this.rule,
    required this.upToHour,
  });

  final List<double> values;
  final Color color;
  final Color track;
  final Color rule;
  final int? upToHour;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = values.fold<double>(0, math.max);
    // Room above the tallest bar for the peak label.
    const labelRoom = 16.0;
    final chartHeight = size.height - labelRoom;
    final slot = size.width / values.length;
    final barWidth = math.max(slot * 0.5, 2.0);
    final radius = Radius.circular(barWidth / 2);

    final rulePaint = Paint()
      ..color = rule
      ..strokeWidth = 1;
    canvas
      ..drawLine(
        const Offset(0, labelRoom),
        Offset(size.width, labelRoom),
        rulePaint,
      )
      ..drawLine(
        Offset(0, size.height - 0.5),
        Offset(size.width, size.height - 0.5),
        rulePaint,
      );

    final fill = Paint()..color = color;
    final stub = Paint()..color = track;

    for (var i = 0; i < values.length; i++) {
      if (upToHour != null && i > upToHour!) break;
      final value = values[i];
      final x = i * slot + (slot - barWidth) / 2;
      final h = peak <= 0 || value <= 0
          ? barWidth
          : math.max(chartHeight * value / peak, barWidth);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          radius,
        ),
        value > 0 ? fill : stub,
      );
    }
  }

  @override
  bool shouldRepaint(_HourlyPainter oldDelegate) =>
      !identical(oldDelegate.values, values) ||
      oldDelegate.color != color ||
      oldDelegate.track != track ||
      oldDelegate.upToHour != upToHour;
}

/// The day's hours as 24 slots, filled where the hour was active: the Stand
/// chart, for active hours.
class ActiveHoursChart extends StatelessWidget {
  const ActiveHoursChart({
    super.key,
    required this.active,
    required this.color,
    this.upToHour,
  });

  final List<bool> active;
  final Color color;
  final int? upToHour;

  @override
  Widget build(BuildContext context) {
    final track = HaloColors.fill.resolveFrom(context);
    final labelStyle = TextStyle(
      color: HaloColors.secondaryLabelOf(context),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 34,
          child: Row(
            children: [
              for (var i = 0; i < active.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        color: active[i]
                            ? color
                            : (upToHour != null && i > upToHour!)
                            ? track.withValues(alpha: track.a * 0.4)
                            : track,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final hour in const ['00:00', '06:00', '12:00', '18:00'])
              Expanded(child: Text(hour, style: labelStyle)),
          ],
        ),
      ],
    );
  }
}
