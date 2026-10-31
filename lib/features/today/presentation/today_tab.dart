import 'package:flutter/cupertino.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/activity/activity_store.dart';
import '../../../data/activity/step_tracker.dart';
import '../../../domain/activity_summary.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/hourly_bars.dart';
import '../../../shared/widgets/placeholder_page.dart';
import '../domain/today_card.dart';
import 'widgets/activity_card.dart';
import 'widgets/metric_tile.dart';
import 'widgets/readiness_card.dart';
import 'widgets/step_access_card.dart';

/// The Today tab: the day at a glance.
///
/// The Activity card is always first, the page's anchor. Everything under it
/// is the user's choice of cards, in the user's order, chosen in the Edit
/// sheet. Wide cards take a row; tiles pair up two to a row.
class TodayTab extends StatefulWidget {
  const TodayTab({super.key});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  /// Created once: a stream made in `build` would resubscribe, and flash its
  /// initial value, on every rebuild.
  Stream<List<TodayCard>>? _cards;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cards ??= HaloScope.preferencesOf(context).watchTodayCards();
  }

  void _open(String title) =>
      Navigator.of(context).push(PlaceholderPage.route(title));

  @override
  Widget build(BuildContext context) {
    final activity = HaloScope.activityOf(context);
    final steps = HaloScope.stepsOf(context);

    return StreamBuilder<List<TodayCard>>(
      stream: _cards,
      initialData: TodayCard.defaults,
      builder: (context, cardsSnapshot) {
        final cards = cardsSnapshot.data ?? TodayCard.defaults;
        return ValueListenableBuilder<StepAccess>(
          valueListenable: steps.access,
          builder: (context, access, _) => ListenableBuilder(
            listenable: activity,
            builder: (context, _) => _buildPage(
              context,
              activity: activity,
              cards: cards,
              access: access,
              onAllow: steps.requestAccess,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required ActivityStore activity,
    required List<TodayCard> cards,
    required StepAccess access,
    required VoidCallback onAllow,
  }) {
    final summary = activity.today;
    final now = DateTime.now();

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
              _DateLabel(date: now),
              const SizedBox(height: 10),
              ActivityCard(
                summary: summary,
                goals: activity.goals,
                onTap: () => _open('Activity'),
              ),
              if (access != StepAccess.granted) ...[
                const SizedBox(height: HaloMetrics.cardGap),
                StepAccessCard(access: access, onAllow: onAllow),
              ],
              for (final row in _rows(cards)) ...[
                const SizedBox(height: HaloMetrics.cardGap),
                _buildRow(context, row, summary, access, now),
              ],
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: HaloMetrics.bottomInset(context)),
        ),
      ],
    );
  }

  /// Groups the cards into rows: a wide card alone, tiles in pairs.
  static List<List<TodayCard>> _rows(List<TodayCard> cards) {
    final rows = <List<TodayCard>>[];
    List<TodayCard>? half;
    for (final card in cards) {
      if (card.wide) {
        if (half != null) {
          rows.add(half);
          half = null;
        }
        rows.add([card]);
      } else if (half == null) {
        half = [card];
      } else {
        rows.add([...half, card]);
        half = null;
      }
    }
    if (half != null) rows.add(half);
    return rows;
  }

  Widget _buildRow(
    BuildContext context,
    List<TodayCard> row,
    ActivitySummary summary,
    StepAccess access,
    DateTime now,
  ) {
    if (row.first.wide) return _buildCard(context, row.first, summary, access, now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildCard(context, row[0], summary, access, now)),
        const SizedBox(width: HaloMetrics.cardGap),
        Expanded(
          child: row.length > 1
              ? _buildCard(context, row[1], summary, access, now)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    TodayCard card,
    ActivitySummary summary,
    StepAccess access,
    DateTime now,
  ) {
    final color = card.color.resolveFrom(context);
    void open() => _open(card.title);

    // Steps only mean something once the counter is running. Before that a
    // zero would read as "you have not moved", which nobody measured.
    final counting = access == StepAccess.granted;

    return switch (card) {
      TodayCard.readiness => ReadinessCard(onTap: open),
      TodayCard.steps => MetricTile(
          title: card.title,
          icon: card.icon,
          color: color,
          caption: 'Today',
          value: counting ? Format.integer(summary.steps) : null,
          unit: 'steps',
          chart: HourlyBars(
            values: summary.hourlySteps,
            color: color,
            trackColor: HaloColors.fill.resolveFrom(context),
            upToHour: now.hour,
          ),
          onTap: open,
        ),
      TodayCard.distance => MetricTile(
          title: card.title,
          icon: card.icon,
          color: color,
          caption: 'Today',
          value: counting ? Format.decimal(summary.distanceKm) : null,
          unit: 'km',
          chart: HourlyBars(
            values: summary.hourlySteps,
            color: color,
            trackColor: HaloColors.fill.resolveFrom(context),
            upToHour: now.hour,
          ),
          onTap: open,
        ),
      _ => MetricTile(
          title: card.title,
          icon: card.icon,
          color: color,
          onTap: open,
        ),
    };
  }
}

/// The date over the first card, small and uppercase, as Fitness and Health
/// put it above their summaries.
class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        Format.longDate(date).toUpperCase(),
        style: TextStyle(
          color: HaloColors.secondaryLabelOf(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
