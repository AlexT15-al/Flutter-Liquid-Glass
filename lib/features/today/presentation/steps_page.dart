import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/activity/activity_history.dart';
import '../../../domain/activity_summary.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import '../../../shared/widgets/hourly_bars.dart';
import '../../../shared/widgets/progress_bar.dart';

/// Steps: today against the goal, hour by hour, the week, and the month.
class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const StepsPage());

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  Future<List<ActivitySummary>>? _month;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_month != null) return;
    final now = DateTime.now();
    _month =
        ActivityHistory(
          HaloScope.databaseOf(context),
          HaloScope.workoutsOf(context),
        ).days(
          now.subtract(const Duration(days: 29)),
          now,
          HaloScope.activityOf(context).profile,
        );
  }

  @override
  Widget build(BuildContext context) {
    final store = HaloScope.activityOf(context);
    final color = HaloColors.steps.resolveFrom(context);
    final secondary = HaloColors.secondaryLabelOf(context);

    return HaloPage(
      appBar: haloBar(context, title: 'Steps'),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final today = store.today;
          final goal = store.goals.steps;
          final week = store.lastDays(7);
          final top = math.max(
            goal * 1.15,
            week.map((d) => d.steps).fold(0, math.max) * 1.05,
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              HaloMetrics.cardPadding,
              HaloMetrics.topInset(context),
              HaloMetrics.cardPadding,
              HaloMetrics.bottomInset(context),
            ),
            children: [
              HaloCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: Format.integer(today.steps),
                            style: TextStyle(
                              color: HaloColors.labelOf(context),
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: ' of ${Format.integer(goal)}',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ProgressBar(
                      value: today.steps / goal,
                      color: color,
                      height: 8,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Stat(
                          value: Format.decimal(today.distanceKm),
                          unit: 'km',
                        ),
                        _Stat(
                          value: Format.integer(today.activeKcal),
                          unit: 'kcal',
                        ),
                        _Stat(
                          value: '${today.activeHours}',
                          unit: 'active hrs',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    HourlyBars(
                      values: today.hourlySteps,
                      color: color,
                      trackColor: HaloColors.fill.resolveFrom(context),
                      height: 90,
                      upToHour: DateTime.now().hour,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final label in ['00', '06', '12', '18', '24'])
                          Text(
                            label,
                            style: TextStyle(color: secondary, fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HaloMetrics.sectionTopGap),
              const GroupCaption('This Week'),
              HaloCard(
                child: SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final day in week)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                day.steps >= 1000
                                    ? '${(day.steps / 1000).toStringAsFixed(1)}k'
                                    : '${day.steps}',
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 18,
                                height: math.max(6, 96 * day.steps / top),
                                decoration: ShapeDecoration(
                                  color: day.steps >= goal
                                      ? color
                                      : color.withValues(alpha: 0.45),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                Format.weekdayLetter(day.day),
                                style: TextStyle(
                                  color: day == week.last
                                      ? HaloColors.labelOf(context)
                                      : secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: HaloMetrics.sectionTopGap),
              const GroupCaption('Last 30 Days'),
              FutureBuilder<List<ActivitySummary>>(
                future: _month,
                builder: (context, snapshot) {
                  final days = snapshot.data ?? const <ActivitySummary>[];
                  final counted = days.where((d) => d.steps > 0).toList();
                  final average = counted.isEmpty
                      ? 0
                      : counted.fold<int>(0, (t, d) => t + d.steps) ~/
                            counted.length;
                  final best = counted.isEmpty
                      ? null
                      : counted.reduce((a, b) => b.steps > a.steps ? b : a);
                  final goalDays = counted.where((d) => d.steps >= goal).length;
                  return GroupedCard(
                    children: [
                      GroupedRow(
                        title: 'Daily Average',
                        value: '${Format.integer(average)} steps',
                      ),
                      GroupedRow(
                        title: 'Best Day',
                        value: best == null
                            ? '—'
                            : '${Format.integer(best.steps)} · '
                                  '${Format.relativeDay(best.day)}',
                      ),
                      GroupedRow(
                        title: 'Goal Reached',
                        value: '$goalDays of ${days.length} days',
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: HaloColors.labelOf(context),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            TextSpan(
              text: ' $unit',
              style: TextStyle(
                color: HaloColors.secondaryLabelOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
