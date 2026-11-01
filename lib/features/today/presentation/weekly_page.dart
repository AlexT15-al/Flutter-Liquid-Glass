import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/activity/activity_history.dart';
import '../../../domain/activity_summary.dart';
import '../../../domain/mindfulness.dart';
import '../../../domain/nutrition.dart';
import '../../../domain/sleep.dart';
import '../../../domain/weekly.dart';
import '../../../domain/workout.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import '../../sleep/sleep_controller.dart';

/// The glyph and colour of what a highlight is about.
(IconData, CupertinoDynamicColor) highlightStyle(
  HighlightKind kind,
) => switch (kind) {
  HighlightKind.steps => (Icons.directions_walk_rounded, HaloColors.steps),
  HighlightKind.move => (CupertinoIcons.flame_fill, HaloColors.move),
  HighlightKind.exercise => (Icons.directions_run_rounded, HaloColors.exercise),
  HighlightKind.workouts => (Icons.fitness_center_rounded, HaloColors.activity),
  HighlightKind.sleep => (CupertinoIcons.bed_double_fill, HaloColors.sleep),
  HighlightKind.water => (CupertinoIcons.drop_fill, HaloColors.hydration),
  HighlightKind.mindful => (CupertinoIcons.sparkles, HaloColors.mindfulness),
};

/// Gathers the last few weeks and hands the review to [builder].
class _WeeklyData extends StatefulWidget {
  const _WeeklyData({required this.builder});

  final Widget Function(BuildContext context, WeeklyReview? review) builder;

  @override
  State<_WeeklyData> createState() => _WeeklyDataState();
}

class _WeeklyDataState extends State<_WeeklyData> {
  /// Long enough for a streak worth having.
  static const _days = 60;

  Future<List<ActivitySummary>>? _summaries;
  Stream<List<WorkoutRecord>>? _workouts;
  Stream<List<SleepNight>>? _nights;
  Stream<List<(int, DateTime, int)>>? _water;
  Stream<List<MindfulSession>>? _mindful;
  Stream<SleepSchedule>? _schedule;
  late DateTime _now;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_summaries != null) return;
    _now = DateTime.now();
    final today = DateTime(_now.year, _now.month, _now.day);
    final from = DateTime(today.year, today.month, today.day - _days + 1);
    final twoWeeks = DateTime(today.year, today.month, today.day - 14);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final workouts = HaloScope.workoutsOf(context);
    _summaries = ActivityHistory(
      HaloScope.databaseOf(context),
      workouts,
    ).days(from, today, HaloScope.activityOf(context).profile);
    _workouts = workouts.watchBetween(from, tomorrow);
    _nights = SleepScope.read(context).repository.watchNights(21);
    _water = HaloScope.nutritionOf(
      context,
    ).watchWaterBetween(twoWeeks, tomorrow);
    _mindful = HaloScope.mindfulnessOf(context).watchSessionsSince(twoWeeks);
    _schedule = HaloScope.preferencesOf(context).watchSleepSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final store = HaloScope.activityOf(context);
    return FutureBuilder<List<ActivitySummary>>(
      future: _summaries,
      builder: (context, days) => StreamBuilder<List<WorkoutRecord>>(
        stream: _workouts,
        initialData: const [],
        builder: (context, workouts) => StreamBuilder<List<SleepNight>>(
          stream: _nights,
          initialData: const [],
          builder: (context, nights) =>
              StreamBuilder<List<(int, DateTime, int)>>(
                stream: _water,
                initialData: const [],
                builder: (context, water) =>
                    StreamBuilder<List<MindfulSession>>(
                      stream: _mindful,
                      initialData: const [],
                      builder: (context, mindful) =>
                          StreamBuilder<SleepSchedule>(
                            stream: _schedule,
                            initialData: const SleepSchedule(),
                            builder: (context, schedule) {
                              final summaries = days.data;
                              if (summaries == null) {
                                return widget.builder(context, null);
                              }
                              return widget.builder(
                                context,
                                WeeklyReview.of(
                                  days: summaries,
                                  workouts: workouts.data ?? const [],
                                  nights: nights.data ?? const [],
                                  water: [
                                    for (final (_, time, ml)
                                        in water.data ??
                                            const <(int, DateTime, int)>[])
                                      (time, ml),
                                  ],
                                  mindful: mindful.data ?? const [],
                                  goals: store.goals,
                                  sleepGoal:
                                      (schedule.data ?? const SleepSchedule())
                                          .goal,
                                  waterGoalMl: NutritionTargets.of(
                                    store.profile,
                                    const WeightGoal(),
                                    today: _now,
                                  ).waterMl,
                                  now: _now,
                                ),
                              );
                            },
                          ),
                    ),
              ),
        ),
      ),
    );
  }
}

String _range(WeeklyReview review) {
  final from = review.from, to = review.to;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return from.month == to.month
      ? '${from.day}–${to.day} ${months[to.month - 1]}'
      : '${from.day} ${months[from.month - 1]} – '
            '${to.day} ${months[to.month - 1]}';
}

/// The Today card: the week's three biggest highlights and its streaks.
class WeeklyCard extends StatelessWidget {
  const WeeklyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _WeeklyData(
      builder: (context, review) {
        final accent = HaloColors.accent.resolveFrom(context);
        final secondary = HaloColors.secondaryLabelOf(context);
        final empty = review == null || review.empty;
        return HaloCard(
          onTap: empty
              ? null
              : () => Navigator.of(context).push(WeeklyPage.route()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.calendar, size: 15, color: accent),
                  const SizedBox(width: 5),
                  Text(
                    'Last 7 Days',
                    style: TextStyle(
                      color: accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (review != null)
                    Text(
                      _range(review),
                      style: TextStyle(color: secondary, fontSize: 13),
                    ),
                  if (!empty) ...[
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 13,
                      color: HaloColors.tertiaryLabelOf(context),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (empty)
                Text(
                  'Your week in review shows up here after a few days of '
                  'steps, sleep or workouts.',
                  style: TextStyle(color: secondary, fontSize: 15),
                )
              else ...[
                for (final h in review.highlights.take(3))
                  _HighlightRow(highlight: h, compact: true),
                if (review.streaks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in review.streaks.take(3))
                        _StreakChip(streak: s),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The week in full: every highlight, this week against the last, and the
/// streaks with their records.
class WeeklyPage extends StatelessWidget {
  const WeeklyPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const WeeklyPage());

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'Last 7 Days'),
      body: _WeeklyData(
        builder: (context, review) {
          if (review == null) return const SizedBox.shrink();
          final now = review.thisWeek, then = review.lastWeek;
          String sleep(Duration? d) =>
              d == null ? '—' : Format.durationWords(d);
          String water(double? ml) =>
              ml == null ? '—' : '${(ml / 1000).toStringAsFixed(1)} L';
          return ListView(
            padding: EdgeInsets.fromLTRB(
              HaloMetrics.cardPadding,
              HaloMetrics.topInset(context),
              HaloMetrics.cardPadding,
              HaloMetrics.bottomInset(context),
            ),
            children: [
              Text(
                _range(review),
                style: TextStyle(
                  color: HaloColors.secondaryLabelOf(context),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: HaloMetrics.cardGap),
              if (review.highlights.isNotEmpty) ...[
                const GroupCaption('Highlights'),
                HaloCard(
                  child: Column(
                    children: [
                      for (final h in review.highlights)
                        _HighlightRow(highlight: h),
                    ],
                  ),
                ),
              ],
              if (review.streaks.isNotEmpty) ...[
                const SizedBox(height: HaloMetrics.sectionTopGap),
                const GroupCaption('Streaks'),
                GroupedCard(
                  children: [
                    for (final s in review.streaks)
                      GroupedRow(
                        leading: _Glyph(kind: s.kind),
                        title: s.title,
                        value:
                            '${s.count} ${s.unit}'
                            '${s.best > s.count ? ' · best ${s.best}' : ''}',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: HaloMetrics.sectionTopGap),
              const GroupCaption('This Week · Week Before'),
              HaloCard(
                child: Column(
                  children: [
                    _Compare(
                      kind: HighlightKind.steps,
                      title: 'Steps a Day',
                      now: Format.integer(now.stepsPerDay.round()),
                      then: Format.integer(then.stepsPerDay.round()),
                      better: _better(now.stepsPerDay, then.stepsPerDay),
                    ),
                    _Compare(
                      kind: HighlightKind.move,
                      title: 'Move a Day',
                      now: '${now.kcalPerDay.round()} kcal',
                      then: '${then.kcalPerDay.round()} kcal',
                      better: _better(now.kcalPerDay, then.kcalPerDay),
                    ),
                    _Compare(
                      kind: HighlightKind.exercise,
                      title: 'Exercise a Day',
                      now: '${now.exercisePerDay.round()} min',
                      then: '${then.exercisePerDay.round()} min',
                      better: _better(now.exercisePerDay, then.exercisePerDay),
                    ),
                    _Compare(
                      kind: HighlightKind.workouts,
                      title: 'Workouts',
                      now: '${now.workouts}',
                      then: '${then.workouts}',
                      better: _better(
                        now.workouts.toDouble(),
                        then.workouts.toDouble(),
                      ),
                    ),
                    _Compare(
                      kind: HighlightKind.sleep,
                      title: 'Sleep a Night',
                      now: sleep(now.sleepPerNight),
                      then: sleep(then.sleepPerNight),
                      better: _better(
                        (now.sleepPerNight?.inMinutes ?? 0).toDouble(),
                        (then.sleepPerNight?.inMinutes ?? 0).toDouble(),
                      ),
                    ),
                    _Compare(
                      kind: HighlightKind.water,
                      title: 'Water a Day',
                      now: water(now.waterPerDay),
                      then: water(then.waterPerDay),
                      better: _better(
                        now.waterPerDay ?? 0,
                        then.waterPerDay ?? 0,
                      ),
                    ),
                    _Compare(
                      kind: HighlightKind.mindful,
                      title: 'Mindful Minutes',
                      now: '${now.mindfulMinutes}',
                      then: '${then.mindfulMinutes}',
                      better: _better(
                        now.mindfulMinutes.toDouble(),
                        then.mindfulMinutes.toDouble(),
                      ),
                      last: true,
                    ),
                  ],
                ),
              ),
              if (now.bestDay case final best?) ...[
                const SizedBox(height: HaloMetrics.sectionTopGap),
                const GroupCaption('Most Active Day'),
                GroupedCard(
                  children: [
                    GroupedRow(
                      leading: const _Glyph(kind: HighlightKind.steps),
                      title: Format.weekday(best.day),
                      value: '${Format.integer(best.steps)} steps',
                    ),
                  ],
                ),
              ],
              const GroupCaption(
                'The last seven full days, ending yesterday, against the '
                'seven before. Streaks count today once its goal is met.',
                footer: true,
              ),
            ],
          );
        },
      ),
    );
  }

  static Trend _better(double now, double then) {
    if (then <= 0 && now <= 0) return Trend.steady;
    if (then <= 0) return Trend.up;
    final change = (now - then) / then;
    if (change >= 0.05) return Trend.up;
    if (change <= -0.05) return Trend.down;
    return Trend.steady;
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.kind, this.size = 30});

  final HighlightKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, dynamicColor) = highlightStyle(kind);
    final color = dynamicColor.resolveFrom(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }
}

class _TrendArrow extends StatelessWidget {
  const _TrendArrow({required this.trend});

  final Trend trend;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (trend) {
      Trend.up => (
        CupertinoIcons.arrow_up_right,
        HaloColors.accent.resolveFrom(context),
      ),
      Trend.down => (
        CupertinoIcons.arrow_down_right,
        CupertinoColors.systemOrange.resolveFrom(context),
      ),
      Trend.steady => (
        CupertinoIcons.arrow_right,
        HaloColors.secondaryLabelOf(context),
      ),
    };
    return Icon(icon, size: 15, color: color);
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight, this.compact = false});

  final Highlight highlight;

  /// On the Today card: the title only.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 5 : 8),
      child: Row(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          _Glyph(kind: highlight.kind, size: compact ? 28 : 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title,
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!compact)
                  Text(
                    highlight.detail,
                    style: TextStyle(
                      color: HaloColors.secondaryLabelOf(context),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          if (highlight.trend != Trend.steady) ...[
            const SizedBox(width: 8),
            _TrendArrow(trend: highlight.trend),
          ],
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final (_, dynamicColor) = highlightStyle(streak.kind);
    final color = dynamicColor.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.16),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.flame_fill, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '${streak.count} ${streak.unit == 'weeks' ? 'wk' : 'd'} '
            '${streak.title}',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Compare extends StatelessWidget {
  const _Compare({
    required this.kind,
    required this.title,
    required this.now,
    required this.then,
    required this.better,
    this.last = false,
  });

  final HighlightKind kind;
  final String title;
  final String now;
  final String then;
  final Trend better;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final secondary = HaloColors.secondaryLabelOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          _Glyph(kind: kind, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: HaloColors.labelOf(context),
                fontSize: 15,
              ),
            ),
          ),
          Text(
            now,
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              then,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: secondary,
                fontSize: 15,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(
            width: 22,
            child: Align(
              alignment: Alignment.centerRight,
              child: better == Trend.steady
                  ? const SizedBox.shrink()
                  : _TrendArrow(trend: better),
            ),
          ),
        ],
      ),
    );
  }
}
