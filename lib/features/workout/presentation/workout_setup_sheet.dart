import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../domain/workout.dart';
import '../../../platform/live_activity.dart';
import '../../../shared/widgets/glass_action_button.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_sheet.dart';
import '../live/workout_controller.dart';

/// Opens the setup for a workout: its goal, then Start.
Future<void> showWorkoutSetup(BuildContext context, WorkoutType type) async {
  final controller = WorkoutScope.read(context);
  final profile = HaloScope.activityOf(context).profile;

  final goal = await showHaloSheet<WorkoutGoal>(
    context,
    builder: (context, scroll) => _SetupSheet(controller: scroll, type: type),
  );
  if (goal == null) return;
  // Notifications first, so the workout can show outside the app.
  await const LiveActivity().prepare();
  await controller.start(type: type, goal: goal, profile: profile);
}

class _SetupSheet extends StatefulWidget {
  const _SetupSheet({required this.controller, required this.type});

  final ScrollController controller;
  final WorkoutType type;

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  WorkoutGoalKind _kind = WorkoutGoalKind.open;

  /// The value each kind starts on, and the one it keeps if the user switches
  /// away and back.
  final Map<WorkoutGoalKind, double> _targets = {
    WorkoutGoalKind.time: 30,
    WorkoutGoalKind.distance: 5,
    WorkoutGoalKind.calories: 300,
  };

  List<WorkoutGoalKind> get _kinds => [
    WorkoutGoalKind.open,
    WorkoutGoalKind.time,
    if (widget.type.hasDistance) WorkoutGoalKind.distance,
    WorkoutGoalKind.calories,
  ];

  WorkoutGoal get _goal => _kind == WorkoutGoalKind.open
      ? WorkoutGoal.open
      : WorkoutGoal(_kind, _targets[_kind]!);

  void _start() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_goal);
  }

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final kinds = _kinds;

    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: widget.type.title,
        leading: SheetButton.close(context),
      ),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
            ),
            child: Icon(widget.type.icon, size: 52, color: accent),
          ),
        ),
        const SizedBox(height: 28),
        HaloCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              GlassSegmentedControl(
                segments: [
                  for (final kind in kinds) GlassSegment(label: kind.label),
                ],
                selectedIndex: kinds.indexOf(_kind),
                onSegmentSelected: (index) =>
                    setState(() => _kind = kinds[index]),
                height: 40,
                borderRadius: 20,
                settings: HaloGlass.of(context),
                quality: HaloGlass.quality,
                useOwnLayer: true,
                selectedTextStyle: DefaultTextStyle.of(context).style.copyWith(
                  color: HaloColors.labelOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                unselectedTextStyle: DefaultTextStyle.of(context).style
                    .copyWith(
                      color: HaloColors.secondaryLabelOf(context),
                      fontSize: 15,
                    ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _kind == WorkoutGoalKind.open
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                        child: Text(
                          'No target. End whenever you like.',
                          style: TextStyle(
                            color: HaloColors.secondaryLabelOf(context),
                            fontSize: 15,
                          ),
                        ),
                      )
                    : _TargetWheel(
                        key: ValueKey(_kind),
                        kind: _kind,
                        value: _targets[_kind]!,
                        onChanged: (v) => _targets[_kind] = v,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GlassActionButton(
          label: 'Start',
          icon: CupertinoIcons.play_fill,
          onTap: _start,
        ),
      ],
    );
  }
}

/// The target for a timed, distance or calorie goal, on a wheel.
class _TargetWheel extends StatefulWidget {
  const _TargetWheel({
    super.key,
    required this.kind,
    required this.value,
    required this.onChanged,
  });

  final WorkoutGoalKind kind;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_TargetWheel> createState() => _TargetWheelState();
}

class _TargetWheelState extends State<_TargetWheel> {
  late final List<double> _values = switch (widget.kind) {
    WorkoutGoalKind.time => [for (var m = 5; m <= 240; m += 5) m.toDouble()],
    WorkoutGoalKind.distance => [
      for (var k = 1; k <= 100; k++) k / 2,
      42.2,
    ]..sort(),
    _ => [for (var c = 50; c <= 1500; c += 25) c.toDouble()],
  };

  late final FixedExtentScrollController _scroll = FixedExtentScrollController(
    initialItem: _nearest(widget.value),
  );

  int _nearest(double value) {
    var best = 0;
    for (var i = 0; i < _values.length; i++) {
      if ((_values[i] - value).abs() < (_values[best] - value).abs()) best = i;
    }
    return best;
  }

  String _label(double value) => switch (widget.kind) {
    WorkoutGoalKind.time => '${value.round()} min',
    WorkoutGoalKind.distance => '${value.toStringAsFixed(1)} km',
    _ => '${value.round()} kcal',
  };

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: CupertinoPicker(
        scrollController: _scroll,
        itemExtent: 36,
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          widget.onChanged(_values[i]);
        },
        children: [
          for (final value in _values) Center(child: Text(_label(value))),
        ],
      ),
    );
  }
}
