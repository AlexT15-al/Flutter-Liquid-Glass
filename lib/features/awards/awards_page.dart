import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

import '../../app/halo_scope.dart';
import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_metrics.dart';
import '../../data/awards/award_stats_loader.dart';
import '../../domain/awards.dart';
import '../../shared/format.dart';
import '../../shared/widgets/grouped_list.dart';
import '../../shared/widgets/halo_alert.dart';
import '../../shared/widgets/halo_page.dart';

/// Awards: medals for what has been done, and how close the rest are.
class AwardsPage extends StatefulWidget {
  const AwardsPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const AwardsPage());

  @override
  State<AwardsPage> createState() => _AwardsPageState();
}

class _AwardsPageState extends State<AwardsPage> {
  Future<AwardStats>? _stats;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stats ??= AwardStatsLoader.load(HaloScope.databaseOf(context));
  }

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'Awards'),
      body: FutureBuilder<AwardStats>(
        future: _stats,
        builder: (context, snapshot) {
          final awards = Award.all(snapshot.data ?? const AwardStats());
          final earned = awards.where((a) => a.earned).length;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  HaloMetrics.cardPadding,
                  HaloMetrics.topInset(context),
                  HaloMetrics.cardPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: GroupCaption('$earned of ${awards.length} earned'),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  HaloMetrics.cardPadding,
                  8,
                  HaloMetrics.cardPadding,
                  HaloMetrics.bottomInset(context),
                ),
                sliver: SliverGrid.builder(
                  itemCount: awards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 168,
                  ),
                  itemBuilder: (context, i) => _Medal(award: awards[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({required this.award});

  final Award award;

  static IconData _icon(AwardKind kind) => switch (kind) {
    AwardKind.workout => CupertinoIcons.flame_fill,
    AwardKind.distance => Icons.directions_run_rounded,
    AwardKind.steps => Icons.directions_walk_rounded,
    AwardKind.sleep => CupertinoIcons.moon_stars_fill,
    AwardKind.nutrition => Icons.restaurant_rounded,
    AwardKind.training => Icons.fitness_center_rounded,
  };

  static Color _color(BuildContext context, AwardKind kind) => switch (kind) {
    AwardKind.workout => HaloColors.move,
    AwardKind.distance => HaloColors.activeHours,
    AwardKind.steps => HaloColors.steps,
    AwardKind.sleep => HaloColors.sleep,
    AwardKind.nutrition => HaloColors.nutrition,
    AwardKind.training => HaloColors.exercise,
  }.resolveFrom(context);

  String _progress() {
    String n(double v) => v >= 1000
        ? Format.integer(v)
        : v == v.roundToDouble()
        ? '${v.round()}'
        : v.toStringAsFixed(1);
    final unit = award.unit.isEmpty ? '' : ' ${award.unit}';
    return award.earned
        ? 'Earned'
        : '${n(math.min(award.current, award.target))} of ${n(award.target)}$unit';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context, award.kind);
    final earned = award.earned;
    final muted = HaloColors.fill.resolveFrom(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showHaloAlert<void>(
        context,
        title: award.title,
        message: '${award.detail}\n${_progress()}.',
        actions: const [HaloAlertAction('OK', style: HaloAlertStyle.primary)],
      ),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 96,
            child: CustomPaint(
              painter: _ProgressRing(
                value: earned ? 0 : award.progress,
                color: color,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: earned ? null : muted,
                    gradient: earned
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(color, const Color(0xFFFFFFFF), 0.35)!,
                              color,
                              Color.lerp(color, const Color(0xFF000000), 0.3)!,
                            ],
                          )
                        : null,
                    boxShadow: earned
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      _icon(award.kind),
                      size: 34,
                      color: earned
                          ? const Color(0xFFFFFFFF)
                          : HaloColors.tertiaryLabelOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            award.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: earned
                  ? HaloColors.labelOf(context)
                  : HaloColors.secondaryLabelOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          Text(
            _progress(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HaloColors.tertiaryLabelOf(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends CustomPainter {
  _ProgressRing({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0) return;
    const stroke = 4.0;
    canvas.drawArc(
      (Offset.zero & size).deflate(stroke / 2),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ProgressRing old) =>
      old.value != value || old.color != color;
}
