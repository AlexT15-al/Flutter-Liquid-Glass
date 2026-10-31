import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/halo_colors.dart';
import '../../../../app/theme/halo_motion.dart';
import '../../../../domain/activity_goals.dart';
import '../../../../domain/activity_summary.dart';
import '../../../../shared/format.dart';
import '../../../../shared/widgets/activity_rings.dart';

/// The last seven days, each as its letter over a small set of rings: the
/// strip across the top of Fitness's Activity screen.
///
/// The selected day sits on a soft squircle that slides to the new day rather
/// than jumping, so the eye follows the selection across the week.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.days,
    required this.goals,
    required this.selected,
    required this.onSelect,
  });

  /// Oldest first, today last.
  final List<ActivitySummary> days;
  final ActivityGoals goals;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  static const double _ringsSize = 34;

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        days.indexWhere((d) => isSameDay(d.day, selected));
    final count = days.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / count;
        return SizedBox(
          height: 70,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration:
                    HaloMotion.of(context, HaloMotion.standardDuration),
                curve: HaloMotion.standardCurve,
                left: slot * selectedIndex.clamp(0, count - 1) + 2,
                top: 0,
                bottom: 0,
                width: slot - 4,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: HaloColors.fill.resolveFrom(context),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final day in days)
                    Expanded(
                      child: _Day(
                        summary: day,
                        goals: goals,
                        selected: isSameDay(day.day, selected),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelect(day.day);
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.summary,
    required this.goals,
    required this.selected,
    required this.onTap,
  });

  final ActivitySummary summary;
  final ActivityGoals goals;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(summary.day, DateTime.now());

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: Format.longDate(summary.day),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Format.weekdayLetter(summary.day),
              style: TextStyle(
                color: isToday
                    ? HaloColors.accent.resolveFrom(context)
                    : HaloColors.secondaryLabelOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ActivityRings(
              size: WeekStrip._ringsSize,
              move: summary.activeKcal / goals.moveKcal,
              exercise: summary.exerciseMinutes / goals.exerciseMinutes,
              activeHours: summary.activeHours / goals.activeHours,
            ),
          ],
        ),
      ),
    );
  }
}
