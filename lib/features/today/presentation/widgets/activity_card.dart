import 'package:flutter/cupertino.dart';

import '../../../../app/theme/halo_colors.dart';
import '../../../../domain/activity_goals.dart';
import '../../../../domain/activity_summary.dart';
import '../../../../shared/format.dart';
import '../../../../shared/widgets/activity_rings.dart';
import '../../../../shared/widgets/halo_card.dart';

/// The Activity card: today's rings and the three numbers behind them.
///
/// Laid out as Fitness lays its Summary card: rings on the leading side, each
/// ring's name and `value/goal` in the ring's own colour beside them, so the
/// colour is the key between ring and number.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.summary,
    required this.goals,
    this.onTap,
  });

  final ActivitySummary summary;
  final ActivityGoals goals;
  final VoidCallback? onTap;

  static const double _ringsSize = 132;

  @override
  Widget build(BuildContext context) {
    final move = summary.activeKcal;
    final exercise = summary.exerciseMinutes;
    final hours = summary.activeHours;

    return HaloCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onTap: onTap),
          const SizedBox(height: 14),
          Row(
            children: [
              ActivityRings(
                size: _ringsSize,
                move: move / goals.moveKcal,
                exercise: exercise / goals.exerciseMinutes,
                activeHours: hours / goals.activeHours,
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RingStat(
                      label: 'Move',
                      value: move.floor(),
                      goal: goals.moveKcal,
                      unit: 'KCAL',
                      color: HaloColors.move.resolveFrom(context),
                    ),
                    const SizedBox(height: 10),
                    _RingStat(
                      label: 'Exercise',
                      value: exercise.floor(),
                      goal: goals.exerciseMinutes,
                      unit: 'MIN',
                      color: HaloColors.exercise.resolveFrom(context),
                    ),
                    const SizedBox(height: 10),
                    _RingStat(
                      label: 'Active Hours',
                      value: hours,
                      goal: goals.activeHours,
                      unit: 'HRS',
                      color: HaloColors.activeHours.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Activity',
          style: TextStyle(
            color: HaloColors.labelOf(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (onTap != null)
          Icon(
            CupertinoIcons.chevron_forward,
            size: 15,
            color: HaloColors.tertiaryLabelOf(context),
          ),
      ],
    );
  }
}

class _RingStat extends StatelessWidget {
  const _RingStat({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  final String label;
  final int value;
  final int goal;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: HaloColors.labelOf(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${Format.integer(value)}/${Format.integer(goal)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: unit,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          style: TextStyle(
            color: color,
            // Fixed-width digits, so the line does not jiggle as a live value
            // ticks up beside a fixed goal.
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1.15,
          ),
        ),
      ],
    );
  }
}
