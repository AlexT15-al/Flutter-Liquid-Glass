import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../domain/intervals.dart';
import '../../../domain/workout.dart';
import '../../../platform/live_activity.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/glass_action_button.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_alert.dart';
import '../../../shared/widgets/halo_sheet.dart';
import '../live/workout_controller.dart';

/// The colour of each kind of interval, here and in the live workout.
Color stepColor(BuildContext context, StepKind kind) => switch (kind) {
  StepKind.warmup => HaloColors.activeHours,
  StepKind.work => HaloColors.move,
  StepKind.recover => HaloColors.hydration,
  StepKind.cooldown => HaloColors.activeHours,
}.resolveFrom(context);

/// Makes a new custom workout, or changes [existing]; saves it and returns
/// it, or null if the sheet was closed.
Future<CustomWorkout?> showCustomWorkoutBuilder(
  BuildContext context, {
  CustomWorkout? existing,
}) async {
  final preferences = HaloScope.preferencesOf(context);
  final result = await showHaloSheet<_BuilderResult>(
    context,
    builder: (context, scroll) => _BuilderSheet(
      controller: scroll,
      initial:
          existing ??
          CustomWorkout.starter(
            WorkoutType.outdoorRun,
            id: DateTime.now().millisecondsSinceEpoch,
          ),
      isNew: existing == null,
    ),
  );
  switch (result) {
    case null:
      return null;
    case _Delete(:final id):
      await preferences.deleteCustomWorkout(id);
      return null;
    case _Save(:final workout):
      await preferences.saveCustomWorkout(workout);
      return workout;
  }
}

/// A custom workout before it starts: its steps, Start, and Edit.
Future<void> showCustomWorkoutStart(
  BuildContext context,
  CustomWorkout workout,
) async {
  final controller = WorkoutScope.read(context);
  final profile = HaloScope.activityOf(context).profile;
  final start = await showHaloSheet<bool>(
    context,
    builder: (context, scroll) =>
        _StartSheet(controller: scroll, workout: workout),
  );
  if (start != true) return;
  await const LiveActivity().prepare();
  await controller.start(
    type: workout.type,
    goal: WorkoutGoal.open,
    profile: profile,
    custom: workout,
  );
}

sealed class _BuilderResult {
  const _BuilderResult();
}

class _Save extends _BuilderResult {
  const _Save(this.workout);
  final CustomWorkout workout;
}

class _Delete extends _BuilderResult {
  const _Delete(this.id);
  final int id;
}

class _BuilderSheet extends StatefulWidget {
  const _BuilderSheet({
    required this.controller,
    required this.initial,
    required this.isNew,
  });

  final ScrollController controller;
  final CustomWorkout initial;
  final bool isNew;

  @override
  State<_BuilderSheet> createState() => _BuilderSheetState();
}

class _BuilderSheetState extends State<_BuilderSheet> {
  late CustomWorkout _workout = widget.initial;
  late final TextEditingController _name = TextEditingController(
    text: widget.initial.name,
  );

  /// Kept while switched off, so switching back on restores them.
  late IntervalStep _warmup =
      widget.initial.warmup ??
      const IntervalStep(StepKind.warmup, StepMeasure.time, 600);
  late IntervalStep _cooldown =
      widget.initial.cooldown ??
      const IntervalStep(StepKind.cooldown, StepMeasure.time, 300);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _set(CustomWorkout workout) => setState(() => _workout = workout);

  /// A distance step only means something where distance is measured.
  IntervalStep _fit(IntervalStep step, WorkoutType type) =>
      !type.hasDistance && step.measure == StepMeasure.distance
      ? step.copyWith(measure: StepMeasure.time, value: 60)
      : step;

  void _setType(WorkoutType type) {
    _set(
      _workout.copyWith(
        type: type,
        warmup: () => _workout.warmup == null ? null : _fit(_warmup, type),
        cooldown: () =>
            _workout.cooldown == null ? null : _fit(_cooldown, type),
        blocks: [
          for (final b in _workout.blocks)
            b.copyWith(
              work: _fit(b.work, type),
              recover: () => b.recover == null ? null : _fit(b.recover!, type),
            ),
        ],
      ),
    );
  }

  void _setBlock(int index, IntervalBlock block) {
    final blocks = [..._workout.blocks];
    blocks[index] = block;
    _set(_workout.copyWith(blocks: blocks));
  }

  void _save() {
    HapticFeedback.mediumImpact();
    final name = _name.text.trim();
    Navigator.of(context).pop(
      _Save(
        _workout.copyWith(
          name: name.isEmpty ? _workout.describe.split(' · ').first : name,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final delete = await confirmDestructive(
      context,
      title: 'Delete ${_workout.name}?',
      action: 'Delete',
    );
    if (delete && mounted) Navigator.of(context).pop(_Delete(_workout.id));
  }

  @override
  Widget build(BuildContext context) {
    final type = _workout.type;
    final secondary = HaloColors.secondaryLabelOf(context);

    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: widget.isNew ? 'New Workout' : 'Edit Workout',
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(onTap: _save, label: 'Save'),
      ),
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            color: HaloColors.card.resolveFrom(context),
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: CupertinoTextField(
            controller: _name,
            placeholder: 'Name',
            decoration: null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            placeholderStyle: TextStyle(color: secondary, fontSize: 17),
          ),
        ),
        const SizedBox(height: 12),
        GroupedCard(
          children: [
            GroupedRow(
              title: 'Workout',
              value: type.title,
              editor: _Wheel<WorkoutType>(
                values: WorkoutType.values,
                selected: type,
                label: (t) => t.title,
                onChanged: _setType,
              ),
            ),
          ],
        ),
        const GroupCaption('Warm Up'),
        GroupedCard(
          children: [
            GroupedRow(
              title: 'Warm Up',
              trailing: _Switch(
                value: _workout.warmup != null,
                label: 'Warm Up',
                onChanged: (on) =>
                    _set(_workout.copyWith(warmup: () => on ? _warmup : null)),
              ),
            ),
            if (_workout.warmup case final w?)
              _StepRow(
                title: 'Length',
                step: w,
                distance: type.hasDistance,
                onChanged: (s) {
                  _warmup = s;
                  _set(_workout.copyWith(warmup: () => s));
                },
              ),
          ],
        ),
        for (var i = 0; i < _workout.blocks.length; i++) ...[
          GroupCaption(
            _workout.blocks.length == 1 ? 'Intervals' : 'Block ${i + 1}',
          ),
          _BlockCard(
            block: _workout.blocks[i],
            distance: type.hasDistance,
            onChanged: (b) => _setBlock(i, b),
            onRemove: _workout.blocks.length == 1
                ? null
                : () => _set(
                    _workout.copyWith(
                      blocks: [..._workout.blocks]..removeAt(i),
                    ),
                  ),
          ),
        ],
        const SizedBox(height: 12),
        GroupedCard(
          children: [
            GroupedRow(
              leading: Icon(
                CupertinoIcons.plus_circle_fill,
                color: HaloColors.accent.resolveFrom(context),
                size: 22,
              ),
              title: 'Add Block',
              onTap: () => _set(
                _workout.copyWith(
                  blocks: [..._workout.blocks, _workout.blocks.last],
                ),
              ),
            ),
          ],
        ),
        const GroupCaption('Cool Down'),
        GroupedCard(
          children: [
            GroupedRow(
              title: 'Cool Down',
              trailing: _Switch(
                value: _workout.cooldown != null,
                label: 'Cool Down',
                onChanged: (on) => _set(
                  _workout.copyWith(cooldown: () => on ? _cooldown : null),
                ),
              ),
            ),
            if (_workout.cooldown case final c?)
              _StepRow(
                title: 'Length',
                step: c,
                distance: type.hasDistance,
                onChanged: (s) {
                  _cooldown = s;
                  _set(_workout.copyWith(cooldown: () => s));
                },
              ),
          ],
        ),
        GroupCaption(
          '${_workout.segments.length} steps · about '
          '${Format.durationWords(_workout.estimate())}'
          '${_hasDistance ? ' at 6:00 /km' : ''}. A double tap marks each '
          'new step, so the phone can stay in a pocket.',
          footer: true,
        ),
        if (!widget.isNew) ...[
          const SizedBox(height: 20),
          GroupedCard(
            children: [
              GroupedRow(
                title: 'Delete Workout',
                destructive: true,
                onTap: _delete,
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  bool get _hasDistance =>
      _workout.segments.any((s) => s.step.measure == StepMeasure.distance);
}

/// Repeats, work and recovery.
class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    required this.distance,
    required this.onChanged,
    required this.onRemove,
  });

  final IntervalBlock block;
  final bool distance;
  final ValueChanged<IntervalBlock> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final recover = block.recover;
    return GroupedCard(
      children: [
        GroupedRow(
          title: 'Repeats',
          trailing: _Counter(
            value: block.repeats,
            min: 1,
            max: 30,
            onChanged: (n) => onChanged(block.copyWith(repeats: n)),
          ),
        ),
        _StepRow(
          title: 'Work',
          step: block.work,
          distance: distance,
          onChanged: (s) => onChanged(block.copyWith(work: s)),
        ),
        GroupedRow(
          title: 'Recover',
          trailing: _Switch(
            value: recover != null,
            label: 'Recover',
            onChanged: (on) => onChanged(
              block.copyWith(
                recover: () => on
                    ? const IntervalStep(StepKind.recover, StepMeasure.time, 90)
                    : null,
              ),
            ),
          ),
        ),
        if (recover != null)
          _StepRow(
            title: 'Recover For',
            step: recover,
            distance: distance,
            onChanged: (s) => onChanged(block.copyWith(recover: () => s)),
          ),
        if (onRemove != null)
          GroupedRow(title: 'Remove Block', destructive: true, onTap: onRemove),
      ],
    );
  }
}

/// A step's length, opening a picker beneath: time or distance, and how
/// much.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.title,
    required this.step,
    required this.distance,
    required this.onChanged,
  });

  final String title;
  final IntervalStep step;
  final bool distance;
  final ValueChanged<IntervalStep> onChanged;

  static const seconds = [
    10, 15, 20, 30, 40, 45, 60, 75, 90, 120, 150, 180, 240, 300, 360, 420, //
    480, 600, 720, 900, 1200, 1500, 1800, 2400, 2700, 3600,
  ];
  static const metres = [
    100, 200, 300, 400, 500, 600, 800, 1000, 1200, 1500, 1600, 2000, //
    2500, 3000, 4000, 5000, 8000, 10000,
  ];

  @override
  Widget build(BuildContext context) {
    final options = step.measure == StepMeasure.time ? seconds : metres;
    final nearest = options.reduce(
      (a, b) => (a - step.value).abs() <= (b - step.value).abs() ? a : b,
    );
    return GroupedRow(
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: stepColor(context, step.kind),
        ),
      ),
      title: title,
      value: step.describe,
      editor: Column(
        children: [
          if (distance)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: GlassSegmentedControl(
                segments: const [
                  GlassSegment(label: 'Time'),
                  GlassSegment(label: 'Distance'),
                ],
                selectedIndex: step.measure.index,
                onSegmentSelected: (i) {
                  final measure = StepMeasure.values[i];
                  if (measure == step.measure) return;
                  onChanged(
                    step.copyWith(
                      measure: measure,
                      value: measure == StepMeasure.time ? 120 : 400,
                    ),
                  );
                },
                height: 36,
                borderRadius: 18,
                settings: HaloGlass.of(context),
                quality: HaloGlass.quality,
                useOwnLayer: true,
                selectedTextStyle: TextStyle(
                  color: HaloColors.labelOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                unselectedTextStyle: TextStyle(
                  color: HaloColors.secondaryLabelOf(context),
                  fontSize: 15,
                ),
              ),
            ),
          _Wheel<int>(
            // A fresh wheel when the measure changes, on its own value.
            key: ValueKey(step.measure),
            values: options,
            selected: nearest,
            label: (v) => step.measure == StepMeasure.time
                ? IntervalStep.describeSeconds(v)
                : IntervalStep.describeMetres(v),
            onChanged: (v) => onChanged(step.copyWith(value: v)),
          ),
        ],
      ),
    );
  }
}

class _Wheel<T> extends StatefulWidget {
  const _Wheel({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  State<_Wheel<T>> createState() => _WheelState<T>();
}

class _WheelState<T> extends State<_Wheel<T>> {
  late final FixedExtentScrollController _scroll = FixedExtentScrollController(
    initialItem: widget.values.indexOf(widget.selected).clamp(0, 1 << 20),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: CupertinoPicker(
        scrollController: _scroll,
        itemExtent: 36,
        onSelectedItemChanged: (i) => widget.onChanged(widget.values[i]),
        children: [
          for (final v in widget.values)
            Center(
              child: Text(
                widget.label(v),
                style: TextStyle(
                  color: HaloColors.labelOf(context),
                  fontSize: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GlassSwitch(
    value: value,
    onChanged: onChanged,
    activeColor: HaloColors.exercise.resolveFrom(context),
    settings: HaloGlass.of(context),
    quality: HaloGlass.quality,
    useOwnLayer: true,
    semanticLabel: label,
  );
}

/// − value +
class _Counter extends StatelessWidget {
  const _Counter({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = HaloColors.labelOf(context);
    Widget button(IconData icon, int? to, String label) => Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: to == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged(to);
              },
        child: SizedBox(
          width: 40,
          height: 36,
          child: Icon(
            icon,
            size: 16,
            color: to == null ? color.withValues(alpha: 0.3) : color,
          ),
        ),
      ),
    );
    return Container(
      height: 36,
      decoration: ShapeDecoration(
        color: HaloColors.fill.resolveFrom(context),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(CupertinoIcons.minus, value > min ? value - 1 : null, 'Fewer'),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          button(CupertinoIcons.plus, value < max ? value + 1 : null, 'More'),
        ],
      ),
    );
  }
}

class _StartSheet extends StatelessWidget {
  const _StartSheet({required this.controller, required this.workout});

  final ScrollController controller;
  final CustomWorkout workout;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final segments = workout.segments;
    // Repeats folded back into one line each, as they were built.
    final lines = <(StepKind, String, String)>[
      if (workout.warmup case final w?)
        (StepKind.warmup, 'Warm Up', w.describe),
      for (final b in workout.blocks) ...[
        (StepKind.work, '${b.repeats} × Work', b.work.describe),
        if (b.recover case final r?)
          (StepKind.recover, '${b.repeats} × Recover', r.describe),
      ],
      if (workout.cooldown case final c?)
        (StepKind.cooldown, 'Cool Down', c.describe),
    ];

    return HaloSheet(
      controller: controller,
      header: HaloSheetHeader(
        title: workout.name,
        leading: SheetButton.close(context),
        trailing: SheetButton(
          icon: CupertinoIcons.pencil,
          label: 'Edit',
          onTap: () async {
            final navigator = Navigator.of(context);
            navigator.pop();
            await showCustomWorkoutBuilder(
              navigator.context,
              existing: workout,
            );
          },
        ),
      ),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
            ),
            child: Icon(workout.type.icon, size: 48, color: accent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${workout.type.title} · ${segments.length} steps · about '
          '${Format.durationWords(workout.estimate())}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: HaloColors.secondaryLabelOf(context),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 20),
        GroupedCard(
          children: [
            for (final (kind, title, value) in lines)
              GroupedRow(
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stepColor(context, kind),
                  ),
                ),
                title: title,
                value: value,
              ),
          ],
        ),
        const SizedBox(height: 24),
        GlassActionButton(
          label: 'Start',
          icon: CupertinoIcons.play_fill,
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
