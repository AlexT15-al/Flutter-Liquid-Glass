import 'package:flutter/cupertino.dart';

import '../../../../app/theme/halo_colors.dart';
import '../../../../domain/sleep.dart';
import '../../../../shared/format.dart';
import 'sleep_colors.dart';

/// The night as a staircase: four rows, awake at the top and deep at the
/// bottom, a rounded bar for every stretch in a stage, and thin joins between
/// one stretch and the next that fade from one colour into the other.
///
/// With [axis], the times along the bottom: in bed, the whole hours between,
/// out of bed. A night without stages draws as one bar of sleep.
class Hypnogram extends StatelessWidget {
  const Hypnogram({
    super.key,
    required this.night,
    this.height = 180,
    this.axis = true,
    this.labels = true,
  });

  final SleepNight night;
  final double height;
  final bool axis;

  /// The stage names down the leading side.
  final bool labels;

  static const order = [
    SleepStage.awake,
    SleepStage.rem,
    SleepStage.light,
    SleepStage.deep,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = {
      for (final s in SleepStage.values) s: stageColor(context, s),
    };
    final secondary = HaloColors.secondaryLabelOf(context);
    final grid = HaloColors.separatorOf(context);

    final chart = CustomPaint(
      size: Size.fromHeight(height),
      painter: _HypnogramPainter(
        stages: night.hasStages
            ? night.hypnogram
            : List.filled(night.timeInBed.inMinutes, SleepStage.light),
        colors: colors,
        grid: grid,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (labels)
              SizedBox(
                width: 52,
                height: height,
                child: Column(
                  children: [
                    for (final stage in order)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            stage.title,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(child: chart),
          ],
        ),
        if (axis) ...[
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: labels ? 52 : 0),
            child: _Axis(night: night, color: secondary),
          ),
        ],
      ],
    );
  }
}

class _Axis extends StatelessWidget {
  const _Axis({required this.night, required this.color});

  final SleepNight night;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = night.timeInBed.inMinutes;
        if (total <= 0) return const SizedBox.shrink();
        final width = constraints.maxWidth;
        // Whole hours in between, thinned out to fit.
        final firstHour = DateTime(
          night.inBed.year,
          night.inBed.month,
          night.inBed.day,
          night.inBed.hour + 1,
        );
        final hours = <DateTime>[
          for (
            var t = firstHour;
            t.isBefore(night.outOfBed);
            t = t.add(const Duration(hours: 1))
          )
            t,
        ];
        final step = (hours.length / 4).ceil().clamp(1, 24);
        return SizedBox(
          height: 14,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                child: Text(Format.timeOfDay(night.inBed), style: style),
              ),
              for (var i = step; i < hours.length; i += step)
                if (hours[i].difference(night.inBed).inMinutes / total > 0.18 &&
                    night.outOfBed.difference(hours[i]).inMinutes / total >
                        0.18)
                  Positioned(
                    left:
                        hours[i].difference(night.inBed).inMinutes /
                            total *
                            width -
                        16,
                    width: 32,
                    child: Text(
                      Format.timeOfDay(hours[i]),
                      style: style,
                      textAlign: TextAlign.center,
                    ),
                  ),
              Positioned(
                right: 0,
                child: Text(Format.timeOfDay(night.outOfBed), style: style),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HypnogramPainter extends CustomPainter {
  _HypnogramPainter({
    required this.stages,
    required this.colors,
    required this.grid,
  });

  final List<SleepStage> stages;
  final Map<SleepStage, Color> colors;
  final Color grid;

  static int _row(SleepStage s) => Hypnogram.order.indexOf(s);

  @override
  void paint(Canvas canvas, Size size) {
    final rows = Hypnogram.order.length;
    final rowHeight = size.height / rows;
    final bar = (rowHeight * 0.52).clamp(4.0, 22.0);

    // Dotted guides along the middle of each row.
    final guide = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var r = 0; r < rows; r++) {
      final y = rowHeight * (r + 0.5);
      for (var x = 0.0; x < size.width; x += 6) {
        canvas.drawLine(Offset(x, y), Offset(x + 2, y), guide);
      }
    }
    if (stages.isEmpty) return;

    final perMinute = size.width / stages.length;
    final runs = <(SleepStage, int, int)>[];
    var start = 0;
    for (var i = 1; i <= stages.length; i++) {
      if (i == stages.length || stages[i] != stages[start]) {
        runs.add((stages[start], start, i));
        start = i;
      }
    }

    // Joins first, under the bars.
    for (var i = 1; i < runs.length; i++) {
      final (a, _, end) = runs[i - 1];
      final b = runs[i].$1;
      final x = end * perMinute;
      final ya = rowHeight * (_row(a) + 0.5);
      final yb = rowHeight * (_row(b) + 0.5);
      final rect = Rect.fromPoints(Offset(x - 1, ya), Offset(x + 1, yb));
      canvas.drawLine(
        Offset(x, ya),
        Offset(x, yb),
        Paint()
          ..strokeWidth = 1.5
          ..shader = LinearGradient(
            begin: ya < yb ? Alignment.topCenter : Alignment.bottomCenter,
            end: ya < yb ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [
              colors[a]!.withValues(alpha: 0.7),
              colors[b]!.withValues(alpha: 0.7),
            ],
          ).createShader(rect),
      );
    }

    for (final (stage, from, to) in runs) {
      final y = rowHeight * (_row(stage) + 0.5);
      final left = from * perMinute;
      final width = ((to - from) * perMinute).clamp(2.0, double.infinity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, y - bar / 2, width, bar),
          Radius.circular(bar / 3.2),
        ),
        Paint()..color = colors[stage]!,
      );
    }
  }

  @override
  bool shouldRepaint(_HypnogramPainter old) =>
      old.stages != stages || old.colors != colors || old.grid != grid;
}
