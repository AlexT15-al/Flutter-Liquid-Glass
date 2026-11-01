import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/training.dart';
import '../../../domain/workout.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/glass_action_button.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import 'rest_timer.dart';

/// A planned session: what to do, and, once started, every set ticked off
/// with its reps and load. Saved, the sets drive next time's plan, and the
/// session counts as a workout in the rings.
class SessionPage extends StatefulWidget {
  const SessionPage({super.key, required this.session, required this.date});

  final PlannedSession session;
  final DateTime date;

  static Route<void> route(PlannedSession session, {required DateTime date}) =>
      CupertinoPageRoute<void>(
        builder: (_) => SessionPage(session: session, date: date),
      );

  @override
  State<SessionPage> createState() => _SessionPageState();
}

/// One set as the user is logging it.
class _Set {
  _Set({required this.reps, this.kg});

  int reps;
  double? kg;
  bool done = false;
}

class _SessionPageState extends State<SessionPage> {
  DateTime? _started;
  late final List<List<_Set>> _sets = [
    for (final e in widget.session.exercises)
      [for (var i = 0; i < e.sets; i++) _Set(reps: e.min, kg: e.kg)],
  ];

  /// The rest under way: when it ends, how long it was, and what is next.
  DateTime? _restEnd;
  Duration _restTotal = Duration.zero;
  String _restNext = '';

  int get _doneCount =>
      _sets.fold(0, (t, sets) => t + sets.where((s) => s.done).length);

  /// A set was ticked off: rest before the next one, if there is one.
  void _setDone(int exercise) {
    final next = _nextSet();
    if (next == null) {
      setState(() => _restEnd = null);
      return;
    }
    final (index, set) = next;
    // Rest for the exercise just finished: the heavy lift needs it, not the
    // one that comes after.
    final rest = widget.session.exercises[exercise].exercise.rest;
    setState(() {
      _restTotal = rest;
      _restEnd = DateTime.now().add(rest);
      _restNext =
          'Set ${set + 1} · ${widget.session.exercises[index].exercise.name}';
    });
  }

  /// The first set not yet done, in order.
  (int, int)? _nextSet() {
    for (var i = 0; i < _sets.length; i++) {
      for (var j = 0; j < _sets[i].length; j++) {
        if (!_sets[i][j].done) return (i, j);
      }
    }
    return null;
  }

  void _adjustRest(int seconds) {
    final end = _restEnd;
    if (end == null) return;
    final moved = end.add(Duration(seconds: seconds));
    final now = DateTime.now();
    setState(() {
      _restEnd = moved.isBefore(now) ? now : moved;
      if (seconds > 0) _restTotal += Duration(seconds: seconds);
    });
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() => _started = DateTime.now());
  }

  Future<void> _finish() async {
    final started = _started!;
    final end = DateTime.now();
    final logs = <SetLog>[
      for (var i = 0; i < _sets.length; i++)
        for (final s in _sets[i])
          if (s.done)
            SetLog(
              time: started,
              exerciseId: widget.session.exercises[i].exercise.id,
              reps: s.reps,
              kg: s.kg,
            ),
    ];
    HapticFeedback.heavyImpact();
    final navigator = Navigator.of(context);
    final profile = HaloScope.activityOf(context).profile;
    final training = HaloScope.trainingOf(context);
    final workouts = HaloScope.workoutsOf(context);
    if (logs.isNotEmpty) {
      await training.saveSession(logs);
      final length = end.difference(started);
      // A strength session in the rings, at the effort of steady lifting.
      const type = WorkoutType.strength;
      await workouts.save(
        WorkoutRecord(
          type: type,
          start: started,
          end: end,
          activeDuration: length,
          distanceKm: 0,
          activeKcal:
              (type.met - 1) *
              profile.weightKg *
              length.inSeconds /
              Duration.secondsPerHour,
          steps: 0,
        ),
      );
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final logging = _started != null;
    final restEnd = _restEnd;
    final bottom = HaloMetrics.bottomInset(context);

    final list = ListView(
      padding: EdgeInsets.fromLTRB(
        HaloMetrics.cardPadding,
        HaloMetrics.topInset(context),
        HaloMetrics.cardPadding,
        bottom + (restEnd == null ? 0 : RestTimer.height + 12),
      ),
      children: [
        Text(
          '${Format.relativeDay(widget.date)} · ${session.exercises.length} '
          'exercises · about ${Format.durationWords(session.length)}',
          style: TextStyle(
            color: HaloColors.secondaryLabelOf(context),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        for (var i = 0; i < session.exercises.length; i++) ...[
          _ExerciseCard(
            planned: session.exercises[i],
            sets: _sets[i],
            logging: logging,
            onChanged: () => setState(() {}),
            onDone: () => _setDone(i),
          ),
          const SizedBox(height: HaloMetrics.cardGap),
        ],
        const SizedBox(height: HaloMetrics.cardGap),
        if (!logging)
          GlassActionButton(
            label: 'Start Session',
            icon: CupertinoIcons.play_fill,
            onTap: _start,
          )
        else
          GlassActionButton(
            label: _doneCount == 0 ? 'Finish' : 'Finish · $_doneCount sets',
            icon: CupertinoIcons.checkmark_alt,
            onTap: _finish,
          ),
      ],
    );

    return HaloPage(
      appBar: haloBar(context, title: session.title),
      body: Stack(
        children: [
          Positioned.fill(child: list),
          Positioned(
            left: HaloMetrics.cardPadding,
            right: HaloMetrics.cardPadding,
            // Just above the tab bar.
            bottom: bottom - 8,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: restEnd == null
                  ? const SizedBox.shrink()
                  : RestTimer(
                      key: const ValueKey('rest'),
                      end: restEnd,
                      total: _restTotal,
                      next: _restNext,
                      onAdjust: _adjustRest,
                      onDone: () => setState(() => _restEnd = null),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.planned,
    required this.sets,
    required this.logging,
    required this.onChanged,
    required this.onDone,
  });

  final PlannedExercise planned;
  final List<_Set> sets;
  final bool logging;
  final VoidCallback onChanged;

  /// A set was ticked off.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final exercise = planned.exercise;
    final secondary = HaloColors.secondaryLabelOf(context);
    final change = planned.change;
    final seconds = exercise.measure == Measure.seconds;

    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (change != 0)
                Text(
                  '${change > 0 ? '+' : '−'}${Format.decimal(change.abs())} kg',
                  style: TextStyle(
                    color: change > 0
                        ? HaloColors.accent.resolveFrom(context)
                        : CupertinoColors.systemOrange.resolveFrom(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          Text(
            planned.target,
            style: TextStyle(
              color: HaloColors.exercise.resolveFrom(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (exercise.cue.isNotEmpty)
            Text(
              exercise.cue,
              style: TextStyle(color: secondary, fontSize: 14),
            ),
          if (logging) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < sets.length; i++)
              _SetRow(
                index: i,
                set: sets[i],
                unit: seconds ? 's' : 'reps',
                step: seconds ? 5 : 1,
                kgStep: exercise.dumbbell
                    ? 2
                    : exercise.lower
                    ? 5
                    : 2.5,
                onChanged: onChanged,
                onDone: onDone,
              ),
          ],
        ],
      ),
    );
  }
}

/// One set: reps (and load) with − and +, and a tick when it is done.
class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.unit,
    required this.step,
    required this.kgStep,
    required this.onChanged,
    required this.onDone,
  });

  final int index;
  final _Set set;
  final String unit;
  final int step;
  final double kgStep;
  final VoidCallback onChanged;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final kg = set.kg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: HaloColors.secondaryLabelOf(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: _Stepper(
              value: '${set.reps} $unit',
              onMinus: set.reps > step
                  ? () {
                      set.reps -= step;
                      onChanged();
                    }
                  : null,
              onPlus: () {
                set.reps += step;
                onChanged();
              },
            ),
          ),
          if (kg != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _Stepper(
                value: '${Format.decimal(kg)} kg',
                onMinus: kg > kgStep
                    ? () {
                        set.kg = kg - kgStep;
                        onChanged();
                      }
                    : null,
                onPlus: () {
                  set.kg = kg + kgStep;
                  onChanged();
                },
              ),
            ),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.mediumImpact();
              set.done = !set.done;
              onChanged();
              if (set.done) onDone();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: set.done ? accent : accent.withValues(alpha: 0.16),
              ),
              child: Icon(
                CupertinoIcons.checkmark_alt,
                size: 20,
                color: set.done
                    ? HaloColors.onAccent.resolveFrom(context)
                    : accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final color = HaloColors.labelOf(context);
    Widget button(IconData icon, VoidCallback? onTap) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: SizedBox(
        width: 32,
        height: 36,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? color.withValues(alpha: 0.3) : color,
        ),
      ),
    );
    return Container(
      height: 36,
      decoration: ShapeDecoration(
        color: HaloColors.fill.resolveFrom(context),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        children: [
          button(CupertinoIcons.minus, onMinus),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          button(CupertinoIcons.plus, onPlus),
        ],
      ),
    );
  }
}
