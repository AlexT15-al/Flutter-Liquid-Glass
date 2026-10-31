import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/activity/activity_history.dart';
import '../../../domain/activity_summary.dart';
import '../../../domain/sleep.dart';
import '../../../domain/trends.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import '../../sleep/sleep_controller.dart';

/// Trends: each measure's last 90 days against its last year, an arrow for
/// which way it is going.
class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const TrendsPage());

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _Data {
  const _Data(this.days, this.nights);

  final List<ActivitySummary> days;
  final List<SleepNight> nights;
}

class _TrendsPageState extends State<TrendsPage> {
  Future<_Data>? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data != null) return;
    final now = DateTime.now();
    final history = ActivityHistory(
      HaloScope.databaseOf(context),
      HaloScope.workoutsOf(context),
    );
    final profile = HaloScope.activityOf(context).profile;
    final sleep = SleepScope.read(context).repository;
    _data = () async {
      final days = await history.days(
        now.subtract(const Duration(days: 364)),
        now,
        profile,
      );
      final nights = await sleep.watchNights(400).first;
      return _Data(days, nights);
    }();
  }

  /// Days of history, from the first day with any steps to today.
  static int _span(_Data data) {
    final first = data.days.indexWhere((d) => d.steps > 0);
    return first < 0 ? 0 : data.days.length - first;
  }

  /// The recent window and the baseline: 90 days against 365 once there is
  /// half a year to compare; before that, the last third against all of it,
  /// so a new user sees which way things are going sooner.
  static (int, int) _windows(_Data data) {
    final span = _span(data);
    if (span >= 180) return (90, 365);
    return ((span / 3).ceil().clamp(7, 90), span);
  }

  static List<Trend> _trends(_Data data) {
    final (recentDays, baselineDays) = _windows(data);
    final all = data.days;
    final days = all.sublist(all.length - baselineDays.clamp(0, all.length));
    final recent = all.sublist(all.length - recentDays.clamp(0, all.length));
    double avg(
      Iterable<ActivitySummary> list,
      double Function(ActivitySummary) f,
    ) => Trend.average(list.map(f));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    double sleepAvg(int withinDays) => Trend.average([
      for (final n in data.nights)
        if (today.difference(n.morning).inDays < withinDays)
          n.asleep.inMinutes / 60,
    ]);

    return [
      Trend(
        title: 'Move',
        unit: 'kcal/day',
        recent: avg(recent, (d) => d.activeKcal),
        year: avg(days, (d) => d.activeKcal),
      ),
      Trend(
        title: 'Exercise',
        unit: 'min/day',
        recent: avg(recent, (d) => d.exerciseMinutes),
        year: avg(days, (d) => d.exerciseMinutes),
      ),
      Trend(
        title: 'Active Hours',
        unit: 'hrs/day',
        recent: avg(recent, (d) => d.activeHours.toDouble()),
        year: avg(days, (d) => d.activeHours.toDouble()),
      ),
      Trend(
        title: 'Steps',
        unit: 'steps/day',
        recent: avg(recent, (d) => d.steps.toDouble()),
        year: avg(days, (d) => d.steps.toDouble()),
      ),
      Trend(
        title: 'Distance',
        unit: 'km/day',
        recent: avg(recent, (d) => d.distanceKm),
        year: avg(days, (d) => d.distanceKm),
      ),
      Trend(
        title: 'Sleep',
        unit: 'hrs/night',
        recent: sleepAvg(recentDays),
        year: sleepAvg(baselineDays),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'Trends'),
      body: FutureBuilder<_Data>(
        future: _data,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final enough =
              data != null && data.days.where((d) => d.steps > 0).length >= 14;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              HaloMetrics.cardPadding,
              HaloMetrics.topInset(context),
              HaloMetrics.cardPadding,
              HaloMetrics.bottomInset(context),
            ),
            children: [
              if (data == null)
                const SizedBox.shrink()
              else if (!enough)
                const GroupCaption(
                  'Trends need a couple of weeks of activity to compare. Keep '
                  'Halo counting your steps and check back.',
                  footer: true,
                )
              else ...[
                for (final trend in _trends(data)) ...[
                  _TrendCard(trend: trend),
                  const SizedBox(height: HaloMetrics.cardGap),
                ],
                GroupCaption(
                  'The average of the last ${_windows(data).$1} days against '
                  'the last ${_windows(data).$2}. Within 3% either way counts '
                  'as steady.',
                  footer: true,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});

  final Trend trend;

  Color _color(BuildContext context) => switch (trend.title) {
    'Move' => HaloColors.move,
    'Exercise' => HaloColors.exercise,
    'Active Hours' => HaloColors.activeHours,
    'Steps' => HaloColors.steps,
    'Distance' => HaloColors.activity,
    _ => HaloColors.sleep,
  }.resolveFrom(context);

  String _value(double v) =>
      v >= 100 ? Format.integer(v) : v.toStringAsFixed(v >= 10 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final direction = trend.direction;
    final shown = trend.good ? color : HaloColors.secondaryLabelOf(context);
    final secondary = HaloColors.secondaryLabelOf(context);

    return HaloCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shown.withValues(alpha: 0.16),
            ),
            child: Icon(
              switch (direction) {
                TrendDirection.up => Icons.arrow_upward_rounded,
                TrendDirection.down => Icons.arrow_downward_rounded,
                TrendDirection.steady => Icons.remove_rounded,
              },
              color: shown,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trend.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _value(trend.recent),
                        style: TextStyle(
                          color: HaloColors.labelOf(context),
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: ' ${trend.unit}',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Before: ${_value(trend.year)} ${trend.unit}',
                  style: TextStyle(color: secondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
