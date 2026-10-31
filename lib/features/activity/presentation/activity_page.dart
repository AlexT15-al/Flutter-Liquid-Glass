import 'package:flutter/cupertino.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../app/theme/halo_motion.dart';
import '../../../data/activity/activity_store.dart';
import '../../../domain/activity_goals.dart';
import '../../../domain/activity_summary.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/activity_rings.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import 'widgets/hourly_chart.dart';
import 'widgets/week_strip.dart';

/// One day of activity in full: the week across the top, the day's rings, and
/// each ring broken down by hour.
///
/// The big rings are the same widget whichever day is selected, so picking
/// another day springs them from one day's values to the other's instead of
/// redrawing. The charts beneath cross-fade, since bars sliding between two
/// unrelated days would suggest a continuity that is not there.
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const ActivityPage());

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  DateTime _selected = DateTime.now();

  static const double _ringsSize = 220;

  @override
  Widget build(BuildContext context) {
    final store = HaloScope.activityOf(context);

    return HaloPage(
      appBar: haloBar(context, title: 'Activity'),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => _buildBody(context, store),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ActivityStore store) {
    final week = store.lastDays(7);
    final day = store.summaryFor(_selected);
    final goals = store.goals;
    final now = DateTime.now();
    // Hours still to come today draw nothing; past days are complete.
    final upToHour = isSameDay(_selected, now) ? now.hour : null;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: HaloMetrics.topInset(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: HaloMetrics.cardPadding,
          ),
          sliver: SliverList.list(
            children: [
              WeekStrip(
                days: week,
                goals: goals,
                selected: _selected,
                onSelect: (value) => setState(() => _selected = value),
              ),
              const SizedBox(height: 24),
              Center(
                child: ActivityRings(
                  size: _ringsSize,
                  move: day.activeKcal / goals.moveKcal,
                  exercise: day.exerciseMinutes / goals.exerciseMinutes,
                  activeHours: day.activeHours / goals.activeHours,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: AnimatedSwitcher(
                  duration:
                      HaloMotion.of(context, HaloMotion.controlSwapDuration),
                  child: Text(
                    Format.relativeDay(_selected),
                    key: ValueKey(Format.longDate(_selected)),
                    style: TextStyle(
                      color: HaloColors.secondaryLabelOf(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration:
                    HaloMotion.of(context, HaloMotion.controlSwapDuration),
                switchInCurve: HaloMotion.standardCurve,
                switchOutCurve: HaloMotion.standardCurve,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: _DayBreakdown(
                  key: ValueKey(Format.longDate(_selected)),
                  day: day,
                  goals: goals,
                  upToHour: upToHour,
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: HaloMetrics.bottomInset(context)),
        ),
      ],
    );
  }
}

/// The three rings by hour, then the day's steps and distance.
class _DayBreakdown extends StatelessWidget {
  const _DayBreakdown({
    super.key,
    required this.day,
    required this.goals,
    required this.upToHour,
  });

  final ActivitySummary day;
  final ActivityGoals goals;
  final int? upToHour;

  @override
  Widget build(BuildContext context) {
    final move = HaloColors.move.resolveFrom(context);
    final exercise = HaloColors.exercise.resolveFrom(context);
    final active = HaloColors.activeHours.resolveFrom(context);

    return Column(
      children: [
        _RingSection(
          title: 'Move',
          value: day.activeKcal.floor(),
          goal: goals.moveKcal,
          unit: 'KCAL',
          color: move,
          chart: HourlyChart(
            values: day.hourlyKcal,
            color: move,
            upToHour: upToHour,
          ),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        _RingSection(
          title: 'Exercise',
          value: day.exerciseMinutes.floor(),
          goal: goals.exerciseMinutes,
          unit: 'MIN',
          color: exercise,
          chart: HourlyChart(
            values: day.hourlyExerciseMinutes,
            color: exercise,
            upToHour: upToHour,
          ),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        _RingSection(
          title: 'Active Hours',
          value: day.activeHours,
          goal: goals.activeHours,
          unit: 'HRS',
          color: active,
          chart: ActiveHoursChart(
            active: day.activeHourFlags,
            color: active,
            upToHour: upToHour,
          ),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        _Totals(day: day),
      ],
    );
  }
}

class _RingSection extends StatelessWidget {
  const _RingSection({
    required this.title,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
    required this.chart,
  });

  final String title;
  final int value;
  final int goal;
  final String unit;
  final Color color;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final percent = goal <= 0 ? 0 : (value / goal * 100).round();

    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: HaloColors.labelOf(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${Format.integer(value)}/${Format.integer(goal)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          TextSpan(
                            text: unit,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: HaloColors.secondaryLabelOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          chart,
        ],
      ),
    );
  }
}

/// Steps and distance side by side, the way Fitness lists them under the
/// rings.
class _Totals extends StatelessWidget {
  const _Totals({required this.day});

  final ActivitySummary day;

  @override
  Widget build(BuildContext context) {
    return HaloCard(
      child: Row(
        children: [
          Expanded(
            child: _Total(
              label: 'Steps',
              value: Format.integer(day.steps),
            ),
          ),
          Container(
            width: HaloMetrics.separatorThickness,
            height: 44,
            color: HaloColors.separatorOf(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _Total(
              label: 'Distance',
              value: Format.decimal(day.distanceKm),
              unit: 'km',
            ),
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: HaloColors.secondaryLabelOf(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: HaloColors.labelOf(context),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: HaloColors.secondaryLabelOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }
}
