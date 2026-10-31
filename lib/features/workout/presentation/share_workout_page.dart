import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/route.dart';
import '../../../domain/workout.dart';
import '../../../platform/share.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/glass_action_button.dart';
import '../../../shared/widgets/halo_alert.dart';
import '../../../shared/widgets/halo_page.dart';

/// A workout as a picture to share: a preview of the card, and Share.
class ShareWorkoutPage extends StatefulWidget {
  const ShareWorkoutPage({super.key, required this.workout});

  final WorkoutRecord workout;

  static Route<void> route(WorkoutRecord workout) => CupertinoPageRoute<void>(
    builder: (_) => ShareWorkoutPage(workout: workout),
  );

  @override
  State<ShareWorkoutPage> createState() => _ShareWorkoutPageState();
}

class _ShareWorkoutPageState extends State<ShareWorkoutPage> {
  final GlobalKey _card = GlobalKey();
  Future<WorkoutRecord>? _full;
  bool _sharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _full ??= HaloScope.workoutsOf(context).withRoute(widget.workout);
  }

  Future<void> _share() async {
    if (_sharing) return;
    _sharing = true;
    HapticFeedback.mediumImpact();
    try {
      final boundary =
          _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // A 1080-pixel-wide picture, whatever the screen.
      final image = await boundary.toImage(
        pixelRatio: 1080 / boundary.size.width,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final w = widget.workout;
      await const SystemShare().image(
        bytes!.buffer.asUint8List(),
        name:
            'Halo ${w.type.title} ${w.start.year}-${w.start.month}-${w.start.day}',
      );
    } on Object catch (error) {
      if (mounted) {
        await showHaloAlert<void>(
          context,
          title: 'Couldn’t Share',
          message: '$error',
          actions: const [HaloAlertAction('OK', style: HaloAlertStyle.cancel)],
        );
      }
    } finally {
      _sharing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'Share'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          HaloMetrics.pagePadding,
          HaloMetrics.topInset(context),
          HaloMetrics.pagePadding,
          HaloMetrics.bottomInset(context),
        ),
        children: [
          FutureBuilder<WorkoutRecord>(
            future: _full,
            initialData: widget.workout,
            builder: (context, snapshot) => RepaintBoundary(
              key: _card,
              child: WorkoutShareCard(workout: snapshot.data ?? widget.workout),
            ),
          ),
          const SizedBox(height: 24),
          GlassActionButton(
            label: 'Share',
            icon: CupertinoIcons.square_arrow_up,
            onTap: _share,
          ),
        ],
      ),
    );
  }
}

/// The card itself: always dark, the accent glowing on it, the route drawn
/// if there was one, and the numbers that matter.
class WorkoutShareCard extends StatelessWidget {
  const WorkoutShareCard({super.key, required this.workout});

  final WorkoutRecord workout;

  static const _accent = Color(0xFFA6FF00);

  @override
  Widget build(BuildContext context) {
    final w = workout;
    final pace = w.distanceKm >= 0.05
        ? Duration(
            milliseconds: (w.activeDuration.inMilliseconds / w.distanceKm)
                .round(),
          )
        : null;
    final cycling = w.type == WorkoutType.outdoorCycle;
    final stats = <(String, String)>[
      if (w.type.hasDistance && w.distanceKm > 0)
        (w.distanceKm.toStringAsFixed(2), 'KM'),
      (Format.clock(w.activeDuration), 'TIME'),
      if (pace != null && w.type.hasDistance)
        cycling
            ? ((3600000 / pace.inMilliseconds).toStringAsFixed(1), 'KM/H')
            : (Format.pace(pace), 'PACE /KM'),
      (Format.integer(w.activeKcal), 'KCAL'),
      if (w.elevationGainM > 0) (Format.integer(w.elevationGainM), 'M UP'),
      if (stats4Fill(w)) (Format.integer(w.steps), 'STEPS'),
    ].take(4).toList();

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(32),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B2410), Color(0xFF000000)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Color(0xFFFFFFFF)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent,
                        ),
                        child: Icon(
                          w.type.icon,
                          color: const Color(0xFF000000),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.type.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              Format.longDate(w.start),
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'HALO',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: w.route.length > 1
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: _RoutePainter(w.route),
                            ),
                          )
                        : Center(
                            child: Icon(
                              w.type.icon,
                              size: 120,
                              color: _accent.withValues(alpha: 0.18),
                            ),
                          ),
                  ),
                  Wrap(
                    runSpacing: 12,
                    children: [
                      for (final (value, unit) in stats)
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              Text(
                                unit,
                                style: const TextStyle(
                                  color: _accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Steps fill the last cell of a workout without distance.
  static bool stats4Fill(WorkoutRecord w) => w.type.steps && w.steps > 0;
}

/// The route as a glowing line, fitted to the space with its proportions
/// kept.
class _RoutePainter extends CustomPainter {
  _RoutePainter(this.route);

  final List<RoutePoint> route;

  @override
  void paint(Canvas canvas, Size size) {
    var minLat = double.infinity, maxLat = -double.infinity;
    var minLon = double.infinity, maxLon = -double.infinity;
    for (final p in route) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude);
      maxLon = math.max(maxLon, p.longitude);
    }
    // Longitude degrees shrink towards the poles.
    final lonScale = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final w = (maxLon - minLon) * lonScale;
    final h = maxLat - minLat;
    if (w <= 0 && h <= 0) return;
    final scale = math.min(
      size.width / (w == 0 ? 1e-9 : w),
      size.height / (h == 0 ? 1e-9 : h),
    );
    final dx = (size.width - w * scale) / 2;
    final dy = (size.height - h * scale) / 2;
    Offset at(RoutePoint p) => Offset(
      dx + (p.longitude - minLon) * lonScale * scale,
      dy + (maxLat - p.latitude) * scale,
    );

    final path = Path();
    for (var i = 0; i < route.length; i++) {
      final o = at(route[i]);
      if (i == 0 || route[i].segment != route[i - 1].segment) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    const accent = WorkoutShareCard._accent;
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = accent.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = accent,
      )
      ..drawCircle(at(route.first), 6, Paint()..color = const Color(0xFFFFFFFF))
      ..drawCircle(at(route.last), 6, Paint()..color = HaloColors.move.color);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.route != route;
}
