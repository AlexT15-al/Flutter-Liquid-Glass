import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/workout.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';

/// One finished workout: when, how long, and what it added up to.
class WorkoutDetailPage extends StatelessWidget {
  const WorkoutDetailPage({super.key, required this.workout});

  final WorkoutRecord workout;

  static Route<void> route(WorkoutRecord workout) => CupertinoPageRoute<void>(
        builder: (_) => WorkoutDetailPage(workout: workout),
      );

  Future<void> _confirmDelete(BuildContext context) async {
    final delete = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text('Its minutes and energy leave your rings too.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (delete != true || !context.mounted) return;
    final id = workout.id;
    if (id != null) await HaloScope.workoutsOf(context).delete(id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final pace = workout.distanceKm >= 0.05
        ? Duration(
            milliseconds:
                (workout.activeDuration.inMilliseconds / workout.distanceKm)
                    .round(),
          )
        : null;

    final cells = <(String, String, String, Color)>[
      (
        'Workout Time',
        Format.clock(workout.activeDuration),
        '',
        accent,
      ),
      (
        'Active Energy',
        Format.integer(workout.activeKcal),
        'KCAL',
        HaloColors.move.resolveFrom(context),
      ),
      if (workout.type.steps) ...[
        (
          'Distance',
          workout.distanceKm.toStringAsFixed(2),
          'KM',
          HaloColors.activeHours.resolveFrom(context),
        ),
        (
          'Steps',
          Format.integer(workout.steps),
          '',
          HaloColors.activity.resolveFrom(context),
        ),
        if (pace != null)
          (
            'Avg. Pace',
            Format.pace(pace),
            '/KM',
            HaloColors.labelOf(context),
          ),
      ],
      if (workout.effort != null)
        (
          'Effort',
          '${workout.effort}',
          '/10',
          CupertinoColors.systemOrange.resolveFrom(context),
        ),
    ];

    return HaloPage(
      appBar: haloBar(
        context,
        title: workout.type.title,
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          HaloMetrics.cardPadding,
          HaloMetrics.topInset(context),
          HaloMetrics.cardPadding,
          HaloMetrics.bottomInset(context),
        ),
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.18),
                ),
                child: Icon(workout.type.icon, size: 30, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Format.relativeDay(workout.start),
                      style: TextStyle(
                        color: HaloColors.labelOf(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_time(workout.start)} – ${_time(workout.end)}',
                      style: TextStyle(
                        color: HaloColors.secondaryLabelOf(context),
                        fontSize: 15,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: HaloMetrics.cardGap,
            runSpacing: HaloMetrics.cardGap,
            children: [
              for (final (title, value, unit, color) in cells)
                LayoutBuilder(
                  builder: (context, _) {
                    final width = (MediaQuery.sizeOf(context).width -
                            HaloMetrics.cardPadding * 2 -
                            HaloMetrics.cardGap) /
                        2;
                    return SizedBox(
                      width: width,
                      child: HaloCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: HaloColors.secondaryLabelOf(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                  if (unit.isNotEmpty)
                                    TextSpan(
                                      text: unit,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                              style: const TextStyle(
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
