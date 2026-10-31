import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A small 24-bar chart of a day's hours, for the tiles.
///
/// Drawn with one painter rather than 24 widgets: it sits in a scrolling grid
/// and repaints with the live step count.
class HourlyBars extends StatelessWidget {
  const HourlyBars({
    super.key,
    required this.values,
    required this.color,
    required this.trackColor,
    this.height = 34,
    this.upToHour,
  });

  final List<num> values;
  final Color color;

  /// The faint stub drawn for an hour with nothing in it.
  final Color trackColor;

  final double height;

  /// Hours after this one have not happened yet and are left blank rather than
  /// drawn as empty.
  final int? upToHour;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarsPainter(
          values: values,
          color: color,
          trackColor: trackColor,
          upToHour: upToHour,
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.color,
    required this.trackColor,
    required this.upToHour,
  });

  final List<num> values;
  final Color color;
  final Color trackColor;
  final int? upToHour;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final count = values.length;
    final peak = values.fold<num>(0, math.max).toDouble();
    final slot = size.width / count;
    final barWidth = math.max(slot * 0.55, 1.5);
    final radius = Radius.circular(barWidth / 2);
    final minBar = barWidth;

    final fill = Paint()..color = color;
    final track = Paint()..color = trackColor;

    for (var i = 0; i < count; i++) {
      if (upToHour != null && i > upToHour!) break;
      final value = values[i].toDouble();
      final x = i * slot + (slot - barWidth) / 2;
      final h = peak <= 0 || value <= 0
          ? minBar
          : math.max(size.height * value / peak, minBar);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          radius,
        ),
        value > 0 ? fill : track,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) =>
      !identical(oldDelegate.values, values) ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.upToHour != upToHour;
}
