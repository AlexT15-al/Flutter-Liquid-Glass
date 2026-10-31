import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/sleep.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/glass_action_button.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/large_title.dart';
import '../sleep_controller.dart';
import 'bedside_page.dart';
import 'night_page.dart';
import 'nights_page.dart';
import 'sleep_sheets.dart';
import 'widgets/hypnogram.dart';
import 'widgets/score_ring.dart';
import 'widgets/sleep_week_chart.dart';

/// The Sleep tab: last night, tonight's plan and the button that starts it,
/// and the week.
class SleepTab extends StatefulWidget {
  const SleepTab({super.key, required this.titleController});

  final GlassLargeTitleController titleController;

  @override
  State<SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends State<SleepTab> {
  Stream<List<SleepNight>>? _nights;
  Stream<SleepSchedule>? _schedule;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nights ??= SleepScope.read(context).repository.watchNights(14);
    _schedule ??= HaloScope.preferencesOf(context).watchSleepSchedule();
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    final controller = SleepScope.read(context);
    final navigator = Navigator.of(context);
    await controller.start();
    navigator.push(BedsidePage.route());
  }

  @override
  Widget build(BuildContext context) {
    final controller = SleepScope.of(context);
    final now = DateTime.now();

    return StreamBuilder<SleepSchedule>(
      stream: _schedule,
      initialData: const SleepSchedule(),
      builder: (context, scheduleSnapshot) {
        final schedule = scheduleSnapshot.data ?? const SleepSchedule();
        return StreamBuilder<List<SleepNight>>(
          stream: _nights,
          initialData: const [],
          builder: (context, snapshot) {
            final nights = snapshot.data ?? const [];
            final today = DateTime(now.year, now.month, now.day);
            final last = nights.isEmpty ? null : nights.first;
            final lastIsRecent =
                last != null && today.difference(last.morning).inDays <= 1;

            return CustomScrollView(
              controller: widget.titleController.scrollController,
              slivers: [
                ...largeTitleSlivers(
                  context,
                  title: 'Sleep',
                  controller: widget.titleController,
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    HaloMetrics.cardPadding,
                    0,
                    HaloMetrics.cardPadding,
                    HaloMetrics.bottomInset(context),
                  ),
                  sliver: SliverList.list(
                    children: [
                      if (controller.tracking)
                        _TrackingCard(controller: controller)
                      else if (lastIsRecent)
                        _LastNightCard(night: last, schedule: schedule)
                      else
                        const _FirstNightCard(),
                      const _SectionTitle('Tonight'),
                      GroupedCard(
                        children: [
                          GroupedRow(
                            title: 'Bedtime',
                            value: Format.minutesOfDay(schedule.bedtimeMinutes),
                            onTap: () => showScheduleSheet(context, schedule),
                          ),
                          GroupedRow(
                            title: 'Wake Up',
                            value: Format.minutesOfDay(schedule.wakeMinutes),
                            onTap: () => showScheduleSheet(context, schedule),
                          ),
                          GroupedRow(
                            title: 'Sleep Goal',
                            value: Format.durationWords(schedule.goal),
                            onTap: () => showScheduleSheet(context, schedule),
                          ),
                        ],
                      ),
                      if (!controller.tracking) ...[
                        const SizedBox(height: HaloMetrics.cardGap + 4),
                        GlassActionButton(
                          label: 'Start Sleep',
                          icon: CupertinoIcons.moon_fill,
                          tint: HaloColors.sleep.resolveFrom(context),
                          ink: const Color(0xFFFFFFFF),
                          onTap: _start,
                        ),
                        const GroupCaption(
                          'Lay your phone on the mattress, near your pillow. '
                          'Halo feels the night through it.',
                          footer: true,
                        ),
                      ],
                      const _SectionTitle('Last 7 Nights'),
                      _WeekCard(nights: nights, schedule: schedule, now: now),
                      const SizedBox(height: HaloMetrics.sectionTopGap),
                      GroupedCard(
                        children: [
                          GroupedRow(
                            title: 'All Nights',
                            onTap: () =>
                                Navigator.of(context).push(NightsPage.route()),
                          ),
                          GroupedRow(
                            title: 'Add Sleep',
                            onTap: () => showAddSleepSheet(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        4,
        HaloMetrics.sectionTopGap,
        4,
        HaloMetrics.sectionTitleGap,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: HaloColors.labelOf(context),
          fontSize: HaloMetrics.sectionTitleSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

/// A caption in the sleep colour over a card's content.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, {this.chevron = false});

  final String text;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.bed_double_fill,
          size: 16,
          color: HaloColors.sleep.resolveFrom(context),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: HaloColors.sleep.resolveFrom(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (chevron)
          Icon(
            CupertinoIcons.chevron_forward,
            size: 15,
            color: HaloColors.tertiaryLabelOf(context),
          ),
      ],
    );
  }
}

class _LastNightCard extends StatelessWidget {
  const _LastNightCard({required this.night, required this.schedule});

  final SleepNight night;
  final SleepSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final noSleep = night.hasStages && night.asleep.inMinutes == 0;
    final label = HaloColors.labelOf(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    final number = TextStyle(
      color: label,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final unit = TextStyle(
      color: secondary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );

    return HaloCard(
      onTap: () => Navigator.of(context).push(NightPage.route(night)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Eyebrow(nightTitle(night), chevron: true),
          const SizedBox(height: 8),
          if (noSleep)
            Text(
              'No sleep detected',
              style: TextStyle(color: secondary, fontSize: 17),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${night.asleep.inHours}',
                              style: number,
                            ),
                            TextSpan(text: ' hr ', style: unit),
                            TextSpan(
                              text: '${night.asleep.inMinutes % 60}',
                              style: number,
                            ),
                            TextSpan(text: ' min', style: unit),
                          ],
                        ),
                      ),
                      Text(
                        '${Format.timeOfDay(night.inBed)} – '
                        '${Format.timeOfDay(night.outOfBed)}',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 15,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                ScoreRing(
                  score: SleepScore.of(night, schedule).value,
                  size: 64,
                  stroke: 7,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Hypnogram(night: night, height: 76, axis: false, labels: false),
          ],
        ],
      ),
    );
  }
}

class _FirstNightCard extends StatelessWidget {
  const _FirstNightCard();

  @override
  Widget build(BuildContext context) {
    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Last Night'),
          const SizedBox(height: 8),
          Text(
            'No sleep yet',
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start Sleep at bedtime, or add a night by hand. Tracked nights '
            'show how long you slept, your stages and a score.',
            style: TextStyle(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// The night in progress, from the tab: back to the clock, or wake up.
class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.controller});

  final SleepController controller;

  Future<void> _wake(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final navigator = Navigator.of(context);
    final night = await controller.stop();
    if (night != null) navigator.push(NightPage.route(night));
  }

  Future<void> _discard(BuildContext context) async {
    final discard = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Discard Tonight?'),
        content: const Text('Tracking stops and nothing is kept.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true) await controller.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final since = controller.since ?? DateTime.now();
    final elapsed = DateTime.now().difference(since);
    return HaloCard(
      onTap: () => Navigator.of(context).push(BedsidePage.route()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Eyebrow('Tracking', chevron: true),
          const SizedBox(height: 8),
          Text(
            'Since ${Format.timeOfDay(since)}',
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            '${Format.durationWords(elapsed)} so far',
            style: TextStyle(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledCapsuleButton(
                  label: 'Wake Up',
                  height: 44,
                  onTap: () => _wake(context),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                onPressed: () => _discard(context),
                child: Text(
                  'Discard',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed.resolveFrom(context),
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The week in bars, with the average and how steady bedtime was.
class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.nights,
    required this.schedule,
    required this.now,
  });

  final List<SleepNight> nights;
  final SleepSchedule schedule;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final chart = SleepWeekChart(
      nights: nights,
      goal: schedule.goal,
      today: now,
    );
    final minutes = chart.minutes.where((m) => m > 0).toList();
    final average = minutes.isEmpty
        ? null
        : Duration(minutes: minutes.reduce((a, b) => a + b) ~/ minutes.length);

    // How far bedtimes strayed from their own average, in minutes. Measured
    // around noon, so 23:50 and 00:10 are twenty minutes apart, not a day.
    final day = DateTime(now.year, now.month, now.day);
    final bedtimes = [
      for (final n in nights)
        if (day.difference(n.morning).inDays < 7)
          ((n.fellAsleep ?? n.inBed).hour * 60 +
                  (n.fellAsleep ?? n.inBed).minute +
                  12 * 60) %
              (24 * 60),
    ];
    int? spread;
    if (bedtimes.length >= 2) {
      final mean = bedtimes.reduce((a, b) => a + b) / bedtimes.length;
      final variance =
          bedtimes.map((b) => (b - mean) * (b - mean)).reduce((a, b) => a + b) /
          bedtimes.length;
      spread = math.sqrt(variance).round();
    }

    final secondary = HaloColors.secondaryLabelOf(context);
    TextStyle caption() =>
        TextStyle(color: secondary, fontSize: 13, fontWeight: FontWeight.w600);
    TextStyle value() => TextStyle(
      color: HaloColors.labelOf(context),
      fontSize: 20,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AVERAGE', style: caption()),
                    Text(
                      average == null ? '—' : Format.durationWords(average),
                      style: value(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BEDTIME', style: caption()),
                    Text(
                      spread == null ? '—' : '± $spread min',
                      style: value(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}
