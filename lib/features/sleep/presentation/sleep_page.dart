import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/phone_use.dart';
import '../../../domain/sleep.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/halo_alert.dart';
import '../../../shared/widgets/glass_action_button.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import '../sleep_controller.dart';
import 'bedside_page.dart';
import 'night_page.dart';
import 'nights_page.dart';
import 'sleep_sheets.dart';
import 'widgets/hypnogram.dart';
import 'widgets/score_ring.dart';
import 'widgets/sleep_week_chart.dart';

/// Sleep: last night and how it went, tonight's plan, and the week.
///
/// Opened from the Sleep card on Today and from Health. Last night comes
/// first the Samsung way, from when the phone was last used and first
/// unlocked; tracking a night on the mattress, which adds stages, comes
/// after.
class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const SleepPage());

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
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

    return HaloPage(
      appBar: haloBar(context, title: 'Sleep'),
      body: StreamBuilder<SleepSchedule>(
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
              final detected = controller.detected;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  HaloMetrics.cardPadding,
                  HaloMetrics.topInset(context),
                  HaloMetrics.cardPadding,
                  HaloMetrics.bottomInset(context),
                ),
                children: [
                  if (controller.tracking)
                    _TrackingCard(controller: controller)
                  else if (detected != null)
                    DetectedSleepCard(estimate: detected)
                  else if (lastIsRecent)
                    _LastNightCard(night: last, schedule: schedule)
                  else
                    const _FirstNightCard(),
                  if (controller.usageAccess == false) ...[
                    const SizedBox(height: HaloMetrics.cardGap),
                    _UsageAccessCard(controller: controller),
                  ],
                  if (detected != null && lastIsRecent) ...[
                    const SizedBox(height: HaloMetrics.cardGap),
                    _LastNightCard(night: last, schedule: schedule),
                  ],
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
                  if (!controller.tracking) ...[
                    const _SectionTitle('Sleep Stages'),
                    GlassActionButton(
                      label: 'Track on the Mattress',
                      icon: CupertinoIcons.moon_fill,
                      tint: HaloColors.sleep.resolveFrom(context),
                      ink: const Color(0xFFFFFFFF),
                      onTap: _start,
                    ),
                    const GroupCaption(
                      'For REM, light and deep sleep, start tracking at '
                      'bedtime and lay the phone on the mattress near your '
                      'pillow. Halo feels the night through it.',
                      footer: true,
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Last night as the phone saw it, waiting to be kept: Record keeps it as it
/// is, Edit changes the times first, as in Samsung Health.
class DetectedSleepCard extends StatelessWidget {
  const DetectedSleepCard({super.key, required this.estimate});

  final SleepEstimate estimate;

  Future<void> _record(BuildContext context, {bool edit = false}) async {
    final controller = SleepScope.read(context);
    final navigator = Navigator.of(context);
    DateTime? from;
    DateTime? to;
    if (edit) {
      final range = await showSleepTimesSheet(
        context,
        title: 'Edit Sleep',
        start: estimate.start,
        end: estimate.end,
      );
      if (range == null) return;
      (from, to) = range;
    }
    HapticFeedback.mediumImpact();
    final night = await controller.record(from: from, to: to);
    if (night != null) navigator.push(NightPage.route(night));
  }

  @override
  Widget build(BuildContext context) {
    final night = estimate.toNight();
    final asleep = night.asleep;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Eyebrow('Sleep Measured'),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${asleep.inHours}', style: number),
                TextSpan(text: ' hr ', style: unit),
                TextSpan(text: '${asleep.inMinutes % 60}', style: number),
                TextSpan(text: ' min', style: unit),
              ],
            ),
          ),
          Text(
            '${Format.timeOfDay(estimate.start)} – '
            '${Format.timeOfDay(estimate.end)}',
            style: TextStyle(
              color: secondary,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From when you last used your phone and first unlocked it.',
            style: TextStyle(color: secondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledCapsuleButton(
                  label: 'Record',
                  height: 44,
                  onTap: () => _record(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlineCapsule(
                  label: 'Edit',
                  onTap: () => _record(context, edit: true),
                ),
              ),
            ],
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(top: 10),
            minimumSize: Size.zero,
            onPressed: () => SleepScope.read(context).dismiss(),
            child: Text(
              'I Wasn\'t Asleep',
              style: TextStyle(
                color: HaloColors.secondaryLabelOf(context),
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A secondary action beside a filled one: the same capsule, tinted fill.
class _OutlineCapsule extends StatelessWidget {
  const _OutlineCapsule({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HaloCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      color: HaloColors.fill.resolveFrom(context),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for Usage Access, which is how Halo knows when the phone was last
/// used at night and first unlocked in the morning.
class _UsageAccessCard extends StatelessWidget {
  const _UsageAccessCard({required this.controller});

  final SleepController controller;

  @override
  Widget build(BuildContext context) {
    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Eyebrow('Measure Sleep Automatically'),
          const SizedBox(height: 6),
          Text(
            'Allow Usage Access and Halo works out each night from when you '
            'last used your phone and first unlocked it in the morning. '
            'Nothing runs at night, and nothing leaves the phone.',
            style: TextStyle(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          FilledCapsuleButton(
            label: 'Allow Usage Access',
            height: 44,
            onTap: controller.requestUsageAccess,
          ),
        ],
      ),
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
    final discard = await confirmDestructive(
      context,
      title: 'Discard Tonight?',
      message: 'Tracking stops and nothing is kept.',
      action: 'Discard',
    );
    if (discard) await controller.cancel();
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
