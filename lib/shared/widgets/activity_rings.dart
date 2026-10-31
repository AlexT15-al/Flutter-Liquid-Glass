import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_motion.dart';

/// The three activity rings, filling with a spring.
///
/// Each ring has its own spring, so when a value changes mid-fill the ring
/// redirects from where it is, at the speed it already has, instead of
/// restarting. On first appearance they fill from empty, the way Fitness
/// opens. Under Reduce Motion they simply show their value.
///
/// The springs drive the painter directly as its repaint listenable, so a
/// filling ring repaints one layer and rebuilds no widgets.
class ActivityRings extends StatefulWidget {
  const ActivityRings({
    super.key,
    required this.move,
    required this.exercise,
    required this.activeHours,
    required this.size,
  });

  /// Progress towards each goal: 0 is empty, 1 is closed, above 1 laps.
  final double move;
  final double exercise;
  final double activeHours;

  final double size;

  @override
  State<ActivityRings> createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<ActivityRings>
    with TickerProviderStateMixin {
  late final List<SingleSpringController> _springs = [
    for (var i = 0; i < 3; i++)
      SingleSpringController(vsync: this, spring: HaloMotion.fill),
  ];

  List<double> get _targets =>
      [widget.move, widget.exercise, widget.activeHours];

  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    _apply();
  }

  @override
  void didUpdateWidget(ActivityRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    _apply();
  }

  void _apply() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final targets = _targets;
    for (var i = 0; i < 3; i++) {
      // Rings lap at most twice over: past that the overlap is unreadable,
      // and the number beside the ring says the rest.
      final target = targets[i].clamp(0.0, 2.0);
      if (reduceMotion) {
        _springs[i].setValue(target);
      } else if (_springs[i].value != target) {
        _springs[i].animateTo(target);
      }
    }
  }

  @override
  void dispose() {
    for (final spring in _springs) {
      spring.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      HaloColors.move.resolveFrom(context),
      HaloColors.exercise.resolveFrom(context),
      HaloColors.activeHours.resolveFrom(context),
    ];

    return Semantics(
      label: 'Activity rings',
      value: 'Move ${(widget.move * 100).round()} percent, '
          'Exercise ${(widget.exercise * 100).round()} percent, '
          'Active Hours ${(widget.activeHours * 100).round()} percent',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _RingsPainter(
            springs: _springs,
            colors: colors,
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.springs, required this.colors})
      : super(repaint: Listenable.merge(springs));

  final List<SingleSpringController> springs;
  final List<Color> colors;

  /// Ring thickness and the gap between rings, as shares of the diameter.
  static const double _thickness = 0.105;
  static const double _gap = 0.014;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = math.min(size.width, size.height);
    final centre = size.center(Offset.zero);
    final stroke = diameter * _thickness;
    final gap = diameter * _gap;

    for (var i = 0; i < 3; i++) {
      final radius = diameter / 2 - stroke / 2 - i * (stroke + gap);
      _paintRing(
        canvas,
        centre: centre,
        radius: radius,
        stroke: stroke,
        color: colors[i],
        progress: springs[i].value,
      );
    }
  }

  void _paintRing(
    Canvas canvas, {
    required Offset centre,
    required double radius,
    required double stroke,
    required Color color,
    required double progress,
  }) {
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = HaloColors.ringTrack(color),
    );

    if (progress <= 0.001) return;

    // The ring darkens towards its start, so the leading cap reads as the
    // brightest point, as on the Fitness rings.
    final dim = Color.lerp(color, const Color(0xFF000000), 0.18)!;
    const start = -math.pi / 2;

    final firstLap = math.min(progress, 1.0);
    final sweep = 2 * math.pi * firstLap;

    // Butt ends, with the caps drawn as circles of their own. A round cap on a
    // sweep gradient takes its colour from the angle it sits at, and the start
    // cap sits just before zero, where the gradient wraps to its brightest
    // colour: the ring would begin with a bright nub instead of its dark end.
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        colors: [dim, color],
        stops: const [0, 1],
        endAngle: math.max(sweep, 0.0001),
        transform: const GradientRotation(start),
      ).createShader(rect);
    Offset at(double angle) =>
        centre + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas
      ..drawCircle(at(start), stroke / 2, Paint()..color = dim)
      ..drawArc(rect, start, sweep, false, arc)
      ..drawCircle(at(start + sweep), stroke / 2, Paint()..color = color);

    if (progress <= 1) return;

    // Past the goal the ring laps over itself. A soft shadow under the leading
    // cap is what separates the second lap from the first.
    final overlap = progress - 1;
    final endAngle = start + 2 * math.pi * overlap;
    final cap = centre + Offset(math.cos(endAngle), math.sin(endAngle)) * radius;
    canvas.drawCircle(
      cap + Offset(math.cos(endAngle + math.pi / 2), math.sin(endAngle + math.pi / 2)) *
          stroke *
          0.12,
      stroke / 2,
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.18),
    );
    canvas.drawArc(
      rect,
      start,
      2 * math.pi * overlap,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) =>
      oldDelegate.colors[0] != colors[0] ||
      oldDelegate.colors[1] != colors[1] ||
      oldDelegate.colors[2] != colors[2];
}
