import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../app/theme/halo_motion.dart';
import '../../../domain/activity_goals.dart';
import '../../../domain/nutrition.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import '../../nutrition/presentation/weight_sheets.dart';

/// Change Goals: the four daily targets, each with − and + around a large
/// number, the way Fitness changes the Move goal.
///
/// Each step is written as it is made, so the rings on Today follow live and
/// there is nothing to confirm.
class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const GoalsPage());

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  Stream<ActivityGoals>? _goals;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _goals ??= HaloScope.preferencesOf(context).watchGoals();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = HaloScope.preferencesOf(context);

    return HaloPage(
      appBar: haloBar(context, title: 'Goals'),
      body: StreamBuilder<ActivityGoals>(
        stream: _goals,
        builder: (context, snapshot) {
          final goals = snapshot.data;
          if (goals == null) return const SizedBox.shrink();
          void save(ActivityGoals next) => preferences.setGoals(next);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              HaloMetrics.cardPadding,
              HaloMetrics.topInset(context),
              HaloMetrics.cardPadding,
              HaloMetrics.bottomInset(context),
            ),
            children: [
              _GoalCard(
                title: 'Move',
                description: 'Active energy to burn each day.',
                color: HaloColors.move.resolveFrom(context),
                value: goals.moveKcal,
                unit: 'KCAL',
                step: 10,
                min: 50,
                max: 3000,
                onChanged: (v) => save(goals.copyWith(moveKcal: v)),
              ),
              const SizedBox(height: HaloMetrics.cardGap),
              _GoalCard(
                title: 'Exercise',
                description: 'Minutes of brisk movement each day.',
                color: HaloColors.exercise.resolveFrom(context),
                value: goals.exerciseMinutes,
                unit: 'MIN',
                step: 5,
                min: 5,
                max: 240,
                onChanged: (v) => save(goals.copyWith(exerciseMinutes: v)),
              ),
              const SizedBox(height: HaloMetrics.cardGap),
              _GoalCard(
                title: 'Active Hours',
                description: 'Hours with at least 250 steps in them.',
                color: HaloColors.activeHours.resolveFrom(context),
                value: goals.activeHours,
                unit: 'HRS',
                step: 1,
                min: 1,
                max: 18,
                onChanged: (v) => save(goals.copyWith(activeHours: v)),
              ),
              const SizedBox(height: HaloMetrics.cardGap),
              _GoalCard(
                title: 'Steps',
                description: 'Steps to take each day.',
                color: HaloColors.steps.resolveFrom(context),
                value: goals.steps,
                unit: 'STEPS',
                step: 500,
                min: 500,
                max: 50000,
                onChanged: (v) => save(goals.copyWith(steps: v)),
              ),
              const SizedBox(height: HaloMetrics.sectionTopGap),
              const GroupCaption('Body'),
              const _WeightGoalCard(),
            ],
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.title,
    required this.description,
    required this.color,
    required this.value,
    required this.unit,
    required this.step,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final String description;
  final Color color;
  final int value;
  final String unit;
  final int step;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return HaloCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StepButton(
                icon: CupertinoIcons.minus,
                color: color,
                label: 'Decrease $title',
                onStep: value - step >= min
                    ? () => onChanged(value - step)
                    : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      Format.integer(value),
                      style: TextStyle(
                        color: HaloColors.labelOf(context),
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        height: 1.05,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StepButton(
                icon: CupertinoIcons.plus,
                color: color,
                label: 'Increase $title',
                onStep: value + step <= max
                    ? () => onChanged(value + step)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A solid circle that steps a value: once on a tap, repeatedly while held.
///
/// Solid rather than glass: it sits on a content card, where glass buttons do
/// not belong. Null [onStep] dims it at the end of the range.
class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onStep,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onStep;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  bool _pressed = false;
  Timer? _repeat;

  /// How long a press has to last before it starts repeating, and how fast it
  /// repeats then.
  static const _holdDelay = Duration(milliseconds: 400);
  static const _holdInterval = Duration(milliseconds: 90);

  void _step() {
    final onStep = widget.onStep;
    if (onStep == null) {
      _stop();
      return;
    }
    HapticFeedback.selectionClick();
    onStep();
  }

  void _start() {
    setState(() => _pressed = true);
    _step();
    _repeat = Timer(_holdDelay, () {
      _repeat = Timer.periodic(_holdInterval, (_) => _step());
    });
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
    if (mounted && _pressed) setState(() => _pressed = false);
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onStep != null;
    final duration = HaloMotion.of(
      context,
      _pressed ? HaloMotion.pressInDuration : HaloMotion.pressOutDuration,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _start() : null,
        onTapUp: enabled ? (_) => _stop() : null,
        onTapCancel: _stop,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: duration,
          curve: HaloMotion.pressCurve,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.35,
            duration: HaloMotion.of(context, HaloMotion.controlSwapDuration),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: Icon(widget.icon, size: 24, color: widget.color),
            ),
          ),
        ),
      ),
    );
  }
}

/// The target weight beside the daily goals: Nutrition and Plans work
/// towards it.
class _WeightGoalCard extends StatelessWidget {
  const _WeightGoalCard();

  @override
  Widget build(BuildContext context) {
    final preferences = HaloScope.preferencesOf(context);
    final activity = HaloScope.activityOf(context);
    return StreamBuilder<WeightGoal>(
      stream: preferences.watchWeightGoal(),
      initialData: const WeightGoal(),
      builder: (context, snapshot) {
        final goal = snapshot.data ?? const WeightGoal();
        final target = goal.targetKg;
        void open() => showWeightGoalSheet(context, activity.profile, goal);
        return GroupedCard(
          children: [
            GroupedRow(
              title: 'Target Weight',
              value: target == null
                  ? 'Not Set'
                  : '${Format.decimal(target)} kg',
              onTap: open,
            ),
            GroupedRow(
              title: 'Pace',
              value:
                  '${goal.pace.title} · ${Format.decimal(goal.pace.kgPerWeek)} kg a week',
              onTap: open,
            ),
          ],
        );
      },
    );
  }
}
