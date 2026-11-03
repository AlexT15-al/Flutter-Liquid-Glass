import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/theme/halo_colors.dart';
import '../format.dart';

/// One bar a day, a week on screen, swiped back through earlier days.
///
/// Today is on the right and selected; tap any bar for its day, shown above
/// the chart with its value. A dashed line marks the goal, and a day that
/// reached it is drawn full strength. The scale is the same across every
/// day, so a bar can be compared with one swiped in from weeks back.
class DayBars extends StatefulWidget {
  const DayBars({
    super.key,
    required this.values,
    required this.lastDay,
    required this.color,
    required this.describe,
    this.goal,
    this.visible = 7,
    this.height = 120,
    this.onSelect,
    this.dot,
    this.initial = 0,
    this.goalIsTarget = true,
  });

  /// Whether reaching the goal is the point (steps), or it is a limit
  /// (calories eaten): only a target is marked as met.
  final bool goalIsTarget;

  /// The day selected at first, in days back from [lastDay]; scrolled into
  /// view.
  final int initial;

  /// A dot over each day's bar, as for a day's mood; null for a day without
  /// one, drawn as an empty dot.
  final Color? Function(DateTime day)? dot;

  /// One value a day, oldest first; the last is [lastDay].
  final List<double> values;

  final DateTime lastDay;
  final Color color;

  /// The selected day's value in words: "8,240 steps", "7 hr 12 min".
  final String Function(double value) describe;

  final double? goal;

  /// Days across the width.
  final int visible;

  final double height;

  /// The day tapped.
  final ValueChanged<DateTime>? onSelect;

  @override
  State<DayBars> createState() => _DayBarsState();
}

class _DayBarsState extends State<DayBars> {
  /// Days back from [DayBars.lastDay]: 0 is the last day.
  late int _selected = widget.initial.clamp(0, 1 << 20);

  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  DateTime _dayAt(int back) => DateTime(
    widget.lastDay.year,
    widget.lastDay.month,
    widget.lastDay.day - back,
  );

  @override
  void didUpdateWidget(DayBars old) {
    super.didUpdateWidget(old);
    if (_selected >= widget.values.length) _selected = 0;
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final secondary = HaloColors.secondaryLabelOf(context);
    final label = HaloColors.labelOf(context);
    final goal = widget.goal;
    final peak = values.isEmpty ? 0.0 : values.reduce(math.max);
    final top = math.max(goal == null ? 1.0 : goal * 1.15, peak * 1.05);
    final selectedValue = values.isEmpty
        ? 0.0
        : values[values.length - 1 - _selected];
    final day = _dayAt(_selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          Format.relativeDay(day).toUpperCase(),
          style: TextStyle(
            color: secondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                widget.describe(selectedValue),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: label,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (widget.goalIsTarget &&
                goal != null &&
                selectedValue >= goal) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.checkmark_seal_fill,
                size: 17,
                color: widget.color,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / widget.visible;
            // First layout: the selected day in the middle, if it is not in
            // the last week anyway.
            _scroll ??= ScrollController(
              initialScrollOffset: _selected < widget.visible
                  ? 0
                  : (_selected - widget.visible / 2 + 0.5) * slot,
            );
            return SizedBox(
              height: widget.height + 22 + (widget.dot == null ? 0 : 18),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                // Today at the right edge, earlier days swiped in from the
                // left.
                reverse: true,
                controller: _scroll,
                itemExtent: slot,
                itemCount: values.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, back) {
                  final value = values[values.length - 1 - back];
                  final date = _dayAt(back);
                  final selected = back == _selected;
                  final met =
                      widget.goalIsTarget && goal != null && value >= goal;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label:
                        '${Format.relativeDay(date)}, '
                        '${widget.describe(value)}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selected = back);
                        widget.onSelect?.call(date);
                      },
                      child: Column(
                        children: [
                          if (widget.dot case final dot?) ...[
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    dot(date) ??
                                    HaloColors.fill.resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          SizedBox(
                            height: widget.height,
                            width: slot,
                            child: CustomPaint(
                              painter: _BarPainter(
                                fraction: (value / top).clamp(0.0, 1.0),
                                goal: goal == null ? null : goal / top,
                                // Continues the dashes from the slot before.
                                dashOffset: back * slot,
                                color: selected
                                    ? widget.color
                                    : widget.color.withValues(
                                        alpha: met ? 0.6 : 0.3,
                                      ),
                                line: secondary,
                                empty: value <= 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            date.weekday == DateTime.monday && !selected
                                ? '${date.day}'
                                : Format.weekdayLetter(date),
                            style: TextStyle(
                              color: selected ? label : secondary,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.fraction,
    required this.goal,
    required this.dashOffset,
    required this.color,
    required this.line,
    required this.empty,
  });

  final double fraction;
  final double? goal;
  final double dashOffset;
  final Color color;
  final Color line;
  final bool empty;

  @override
  void paint(Canvas canvas, Size size) {
    final width = math.min(18.0, size.width * 0.5);
    final x = (size.width - width) / 2;
    if (!empty) {
      final height = math.max(width, size.height * fraction);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - height, width, height),
          Radius.circular(width / 2),
        ),
        Paint()..color = color,
      );
    } else {
      // A day without any: a dot, so the day is still there.
      canvas.drawCircle(
        Offset(size.width / 2, size.height - 3),
        3,
        Paint()..color = color,
      );
    }
    final g = goal;
    if (g != null && g <= 1) {
      final y = size.height * (1 - g);
      final paint = Paint()
        ..color = line.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      const dash = 4.0, period = 8.0;
      // Measured from the chart's right edge, where the list starts, so
      // the dashes run on unbroken from one day's slot to the next.
      final from = dashOffset;
      final to = dashOffset + size.width;
      for (var d = (from / period).floor() * period; d < to; d += period) {
        final a = math.max(d, from);
        final b = math.min(d + dash, to);
        if (b <= a) continue;
        canvas.drawLine(
          Offset(size.width - (b - from), y),
          Offset(size.width - (a - from), y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fraction != fraction ||
      old.goal != goal ||
      old.color != color ||
      old.line != line ||
      old.empty != empty;
}
