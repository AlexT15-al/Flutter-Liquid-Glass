import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/sleep.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/halo_alert.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../sleep_controller.dart';
import 'widgets/hypnogram.dart';
import 'widgets/score_ring.dart';
import 'widgets/sleep_colors.dart';

/// "Last Night" for the night that ended this morning; otherwise the
/// morning it ended on.
String nightTitle(SleepNight night) {
  final title = Format.relativeDay(night.morning);
  return title == 'Today' ? 'Last Night' : title;
}

/// One night in full: its score and what made it, the stages, and the times.
class NightPage extends StatelessWidget {
  const NightPage({super.key, required this.night});

  final SleepNight night;

  static Route<void> route(SleepNight night) =>
      CupertinoPageRoute<void>(builder: (_) => NightPage(night: night));

  Future<void> _confirmDelete(BuildContext context) async {
    final delete = await confirmDestructive(
      context,
      title: 'Delete This Night?',
      action: 'Delete',
    );
    if (!delete || !context.mounted) return;
    final id = night.id;
    if (id != null) await SleepScope.read(context).repository.delete(id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = HaloScope.preferencesOf(context);

    return HaloPage(
      appBar: haloBar(
        context,
        title: nightTitle(night),
        actions: [
          GlassBarItem.icon(
            id: 'delete',
            label: 'Delete',
            background: GlassBarItemBackground.separate,
            icon: Icon(
              CupertinoIcons.trash,
              size: HaloMetrics.barButtonSize * HaloMetrics.barGlyphRatio,
              color: CupertinoColors.destructiveRed.resolveFrom(context),
            ),
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
      body: StreamBuilder<SleepSchedule>(
        stream: preferences.watchSleepSchedule(),
        initialData: const SleepSchedule(),
        builder: (context, snapshot) {
          final schedule = snapshot.data ?? const SleepSchedule();
          return ListView(
            padding: EdgeInsets.fromLTRB(
              HaloMetrics.cardPadding,
              HaloMetrics.topInset(context),
              HaloMetrics.cardPadding,
              HaloMetrics.bottomInset(context),
            ),
            children: NightDetails.sections(context, night, schedule),
          );
        },
      ),
    );
  }
}

/// The sections of a night's page, shared with the morning summary.
abstract final class NightDetails {
  static List<Widget> sections(
    BuildContext context,
    SleepNight night,
    SleepSchedule schedule,
  ) {
    final asleep = night.asleep;
    if (night.hasStages && asleep.inMinutes == 0) {
      return [
        HaloCard(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.moon_zzz_fill,
                size: 40,
                color: HaloColors.sleep.resolveFrom(context),
              ),
              const SizedBox(height: 10),
              Text(
                'No Sleep Detected',
                style: TextStyle(
                  color: HaloColors.labelOf(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The bed hardly stayed still for ten minutes in a row. '
                'Lay the phone on the mattress near your pillow, not on a '
                'nightstand.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HaloColors.secondaryLabelOf(context),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final score = SleepScore.of(night, schedule);
    final fellAsleep = night.fellAsleep;
    final wokeUp = night.wokeUp;
    final efficiency = night.efficiency;

    return [
      _Header(night: night, score: score),
      const SizedBox(height: HaloMetrics.cardGap),
      HaloCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hypnogram(night: night),
            if (night.hasStages) ...[
              const SizedBox(height: 14),
              _StageList(night: night),
            ],
          ],
        ),
      ),
      const SizedBox(height: HaloMetrics.sectionTopGap),
      const GroupCaption('Times'),
      GroupedCard(
        children: [
          GroupedRow(title: 'In Bed', value: Format.timeOfDay(night.inBed)),
          if (night.hasStages && fellAsleep != null)
            GroupedRow(
              title: 'Fell Asleep',
              value:
                  '${Format.timeOfDay(fellAsleep)} · '
                  '${Format.durationWords(fellAsleep.difference(night.inBed))}',
            ),
          if (night.hasStages && wokeUp != null)
            GroupedRow(title: 'Woke Up', value: Format.timeOfDay(wokeUp)),
          GroupedRow(
            title: 'Out of Bed',
            value: Format.timeOfDay(night.outOfBed),
          ),
          if (efficiency != null)
            GroupedRow(
              title: 'Efficiency',
              value: '${(efficiency * 100).round()}%',
            ),
          if (night.hasStages)
            GroupedRow(title: 'Awakenings', value: '${night.awakenings}'),
        ],
      ),
      const SizedBox(height: HaloMetrics.sectionTopGap),
      const GroupCaption('Score'),
      HaloCard(
        child: Column(
          children: [
            _Part(
              title: 'Duration',
              detail:
                  '${Format.durationWords(asleep)} of '
                  '${Format.durationWords(schedule.goal)}',
              value: score.duration,
            ),
            if (score.efficiency case final e?)
              _Part(
                title: 'Efficiency',
                detail:
                    'Asleep for ${(efficiency! * 100).round()}% of the time in bed',
                value: e,
              ),
            if (score.continuity case final c?)
              _Part(
                title: 'Continuity',
                detail:
                    '${night.awakenings} awakenings, '
                    '${Format.durationWords(night.awakeDuringSleep)} awake',
                value: c,
              ),
            _Part(
              title: 'Timing',
              detail: 'Bedtime ${Format.minutesOfDay(schedule.bedtimeMinutes)}',
              value: score.timing,
              last: true,
            ),
          ],
        ),
      ),
      GroupCaption(switch (night.source) {
        SleepSource.tracked =>
          'Stages are estimated from how the bed moved and the usual shape '
              'of a night. They are a guide, not a medical measurement.',
        SleepSource.phone =>
          'Measured from when you last used your phone and first unlocked '
              'it. Track a night on the mattress to see its stages.',
        SleepSource.manual =>
          'Entered by hand. Track a night on the mattress to see its stages.',
      }, footer: true),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.night, required this.score});

  final SleepNight night;
  final SleepScore score;

  @override
  Widget build(BuildContext context) {
    final hours = night.asleep.inHours;
    final minutes = night.asleep.inMinutes % 60;
    final label = HaloColors.labelOf(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    final number = TextStyle(
      color: label,
      fontSize: 38,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final unit = TextStyle(
      color: secondary,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    );

    return HaloCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASLEEP',
                  style: TextStyle(
                    color: HaloColors.sleep.resolveFrom(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$hours', style: number),
                      TextSpan(text: ' hr ', style: unit),
                      TextSpan(text: '$minutes', style: number),
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
          Column(
            children: [
              ScoreRing(score: score.value, size: 84, stroke: 9),
              const SizedBox(height: 6),
              Text(
                score.label,
                style: TextStyle(
                  color: secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Each stage: its colour, its time, its share of the night.
class _StageList extends StatelessWidget {
  const _StageList({required this.night});

  final SleepNight night;

  @override
  Widget build(BuildContext context) {
    final minutes = night.stageMinutes;
    final total = minutes.values.fold(0, (a, b) => a + b);
    return Column(
      children: [
        for (final stage in Hypnogram.rowsFor(night))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stageColor(context, stage),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stage.title,
                    style: TextStyle(
                      color: HaloColors.labelOf(context),
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  Format.durationWords(Duration(minutes: minutes[stage]!)),
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    total == 0
                        ? '—'
                        : '${(minutes[stage]! / total * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: HaloColors.secondaryLabelOf(context),
                      fontSize: 15,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One part of the score: what it is, what it was, and a bar for how well.
class _Part extends StatelessWidget {
  const _Part({
    required this.title,
    required this.detail,
    required this.value,
    this.last = false,
  });

  final String title;
  final String detail;
  final double value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = HaloColors.sleep.resolveFrom(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                detail,
                style: TextStyle(
                  color: HaloColors.secondaryLabelOf(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(value: value.clamp(0.0, 1.0), color: color),
        ],
      ),
    );
  }
}
