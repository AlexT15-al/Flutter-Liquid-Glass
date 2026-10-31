import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/activity/activity_store.dart';
import '../../../data/activity/step_tracker.dart';
import '../../../domain/activity_summary.dart';
import '../../../domain/sleep.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/hourly_bars.dart';
import '../../../shared/widgets/large_title.dart';
import '../../../shared/widgets/placeholder_page.dart';
import '../../activity/presentation/activity_page.dart';
import '../../sleep/presentation/night_page.dart';
import '../../sleep/presentation/sleep_page.dart';
import '../../sleep/presentation/widgets/hypnogram.dart';
import '../../sleep/sleep_controller.dart';
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
  const TodayTab({super.key, required this.titleController});

  /// Drives the large title in the content and the small one in the bar.
  final GlassLargeTitleController titleController;

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
      controller: widget.titleController.scrollController,
      slivers: [
        ...largeTitleSlivers(
          context,
          title: 'Today',
          controller: widget.titleController,
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
                onTap: () => Navigator.of(context).push(ActivityPage.route()),
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
    if (row.first.wide) {
      return _buildCard(context, row.first, summary, access, now);
    }

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
      TodayCard.sleep => _SleepTile(card: card, color: color),
      _ => MetricTile(
        title: card.title,
        icon: card.icon,
        color: color,
        onTap: open,
      ),
    };
  }
}

/// Last night, from the Sleep tab: how long, and its shape.
class _SleepTile extends StatefulWidget {
  const _SleepTile({required this.card, required this.color});

  final TodayCard card;
  final Color color;

  @override
  State<_SleepTile> createState() => _SleepTileState();
}

class _SleepTileState extends State<_SleepTile> {
  Stream<List<SleepNight>>? _nights;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nights ??= SleepScope.read(context).repository.watchNights(1);
  }

  @override
  Widget build(BuildContext context) {
    final sleep = SleepScope.of(context);
    return StreamBuilder<List<SleepNight>>(
      stream: _nights,
      initialData: const [],
      builder: (context, snapshot) {
        final nights = snapshot.data ?? const [];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        // Only a night that ended this morning or yesterday's is "last".
        final recorded =
            nights.isNotEmpty &&
                today.difference(nights.first.morning).inDays <= 1
            ? nights.first
            : null;
        // Measured from the phone this morning and not yet recorded: shown
        // as it is, for a tap to keep or change.
        final detected = sleep.detected;
        final night = detected?.toNight() ?? recorded;
        final asleep = night?.asleep;
        return MetricTile(
          title: widget.card.title,
          icon: widget.card.icon,
          color: widget.color,
          caption: detected != null
              ? 'Measured · Tap to Record'
              : night == null
              ? null
              : nightTitle(night),
          value: asleep == null || asleep.inMinutes == 0
              ? null
              : '${asleep.inHours}:'
                    '${(asleep.inMinutes % 60).toString().padLeft(2, '0')}',
          unit: 'hr',
          chart: night == null || !night.hasStages
              ? null
              : Hypnogram(night: night, height: 34, axis: false, labels: false),
          onTap: () => Navigator.of(context).push(SleepPage.route()),
        );
      },
    );
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
