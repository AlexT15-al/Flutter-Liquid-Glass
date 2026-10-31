import 'package:flutter/cupertino.dart';

import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/route.dart';
import '../../../domain/workout.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/halo_card.dart';
import 'route_map.dart';

/// A finished route, framed, in a card.
class RouteMapCard extends StatelessWidget {
  const RouteMapCard({super.key, required this.route});

  final List<RoutePoint> route;

  @override
  Widget build(BuildContext context) {
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(HaloMetrics.cardRadius),
      child: SizedBox(height: 220, child: RouteMap(route: route)),
    );
  }
}

/// Time for each kilometre, with a bar that is longest for the fastest one,
/// so the even and the uneven parts of a run show at a glance.
///
/// Cycling reads in speed rather than pace, the way a bike computer does.
class SplitsCard extends StatelessWidget {
  const SplitsCard({super.key, required this.splits, required this.type});

  final List<RouteSplit> splits;
  final WorkoutType type;

  bool get _speed => type == WorkoutType.outdoorCycle;

  static double kmh(Duration perKm) =>
      perKm.inMilliseconds <= 0 ? 0 : 3600000 / perKm.inMilliseconds;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    final label = HaloColors.labelOf(context);
    final fastest = splits
        .map((s) => s.pace.inMilliseconds)
        .fold<int>(1 << 62, (a, b) => b < a ? b : a);

    TextStyle header() =>
        TextStyle(color: secondary, fontSize: 13, fontWeight: FontWeight.w600);

    return HaloCard(
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 44, child: Text('KM', style: header())),
              SizedBox(
                width: 76,
                child: Text(_speed ? 'KM/H' : 'PACE', style: header()),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final split in splits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      split.partial == null
                          ? '${split.index}'
                          : (split.index - 1 + split.partial!).toStringAsFixed(
                              2,
                            ),
                      style: TextStyle(
                        color: secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    child: Text(
                      _speed
                          ? kmh(split.pace).toStringAsFixed(1)
                          : Format.pace(split.pace),
                      style: TextStyle(
                        color: label,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: split.pace.inMilliseconds <= 0
                            ? 0
                            : (fastest / split.pace.inMilliseconds).clamp(
                                0.08,
                                1.0,
                              ),
                        child: Container(
                          height: 10,
                          decoration: ShapeDecoration(
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            color: split.partial == null
                                ? accent
                                : accent.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
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

/// A caption over a section of a workout's page.
class WorkoutSectionTitle extends StatelessWidget {
  const WorkoutSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: HaloColors.secondaryLabelOf(context),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
