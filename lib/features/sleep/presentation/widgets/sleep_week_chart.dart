import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../app/theme/halo_colors.dart';
import '../../../../domain/sleep.dart';
import '../../../../shared/format.dart';

/// Sleep on each of the last seven mornings against the goal, a dashed line
/// across the bars.
class SleepWeekChart extends StatelessWidget {
  const SleepWeekChart({
    super.key,
    required this.nights,
    required this.goal,
    required this.today,
  });

  final List<SleepNight> nights;
  final Duration goal;
  final DateTime today;

  /// Minutes asleep for each of the seven mornings ending [today], oldest
  /// first; a morning with two sessions (a nap after a short night) adds up.
  List<int> get minutes {
    final day = DateTime(today.year, today.month, today.day);
    final out = List.filled(7, 0);
    for (final night in nights) {
      final index = 6 - day.difference(night.morning).inDays;
      if (index >= 0 && index < 7) out[index] += night.asleep.inMinutes;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final values = minutes;
    final color = HaloColors.sleep.resolveFrom(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    final day = DateTime(today.year, today.month, today.day);
    final top = math.max(goal.inMinutes * 1.2, values.reduce(math.max) * 1.05);

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: CustomPaint(
            size: Size.infinite,
            painter: _WeekPainter(
              values: values,
              top: top,
              goal: goal.inMinutes.toDouble(),
              bar: color,
              track: HaloColors.ringTrack(color),
              line: secondary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  Format.weekdayLetter(day.subtract(Duration(days: 6 - i))),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: i == 6 ? HaloColors.labelOf(context) : secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekPainter extends CustomPainter {
  _WeekPainter({
    required this.values,
    required this.top,
    required this.goal,
    required this.bar,
    required this.track,
    required this.line,
  });

  final List<int> values;
  final double top;
  final double goal;
  final Color bar;
  final Color track;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / values.length;
    final width = math.min(22.0, slot * 0.5);
    for (var i = 0; i < values.length; i++) {
      final x = slot * (i + 0.5) - width / 2;
      final full = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, width, size.height),
        Radius.circular(width / 2),
      );
      canvas.drawRRect(full, Paint()..color = track);
      if (values[i] <= 0) continue;
      final h = (values[i] / top * size.height).clamp(width, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, width, h),
          Radius.circular(width / 2),
        ),
        Paint()..color = bar,
      );
    }
    final y = size.height - goal / top * size.height;
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, y), Offset(x + 3.5, y), paint);
    }
  }

  @override
  bool shouldRepaint(_WeekPainter old) =>
      old.values != values ||
      old.top != top ||
      old.goal != goal ||
      old.bar != bar;
}
