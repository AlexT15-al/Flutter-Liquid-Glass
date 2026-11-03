import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/training.dart';
import '../../../domain/warm_up.dart';
import '../../../domain/workout.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/glass_action_button.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import 'rest_timer.dart';
import 'swap_sheet.dart';

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

  /// The session as planned, again after an exercise is swapped.
  late PlannedSession _session = widget.session;

  late final List<List<_Set>> _sets = [
    for (final e in _session.exercises) _setsFor(e),
  ];

  static List<_Set> _setsFor(PlannedExercise e) => [
    for (var i = 0; i < e.sets; i++) _Set(reps: e.min, kg: e.kg),
  ];

  /// Warm-up moves ticked off, by index.
  final Set<int> _warmedUp = {};

  /// Swaps exercise [index] for another that trains the same movement, or
  /// puts the plan's own choice back; kept for every session after.
  Future<void> _swap(int index) async {
    final planned = _session.exercises[index];
    final choice = await showSwapSheet(context, planned);
    if (choice == null || !mounted) return;
    final preferences = HaloScope.preferencesOf(context);
    final body = HaloScope.activityOf(context).profile;
    final training = HaloScope.trainingOf(context);
    final profile =
        await preferences.watchTraining().first ?? const TrainingProfile();
    final next = profile.swapped(planned.slot, choice.id);
    await preferences.setTraining(next);
    final goal = await preferences.watchWeightGoal().first;
    final history = await training.watchHistory().first;
    final week = TrainingPlanner.week(
      training: next,
      body: body,
      goal: goal,
      history: history,
    );
    final session = week
        .where((s) => s.weekday == _session.weekday)
        .firstOrNull;
    if (session == null || !mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _session = session;
      if (index < session.exercises.length) {
        _sets[index] = _setsFor(session.exercises[index]);
      }
    });
  }

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
    final rest = _session.exercises[exercise].exercise.rest;
    setState(() {
      _restTotal = rest;
      _restEnd = DateTime.now().add(rest);
      _restNext = 'Set ${set + 1} · ${_session.exercises[index].exercise.name}';
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
              exerciseId: _session.exercises[i].exercise.id,
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
    final session = _session;
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
        _WarmUpCard(
          moves: WarmUp.general(
            session,
            session.exercises.firstOrNull?.exercise.place ?? TrainingPlace.gym,
          ),
          done: _warmedUp,
          onToggle: (i) => setState(() {
            HapticFeedback.selectionClick();
            if (!_warmedUp.remove(i)) _warmedUp.add(i);
          }),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        for (var i = 0; i < session.exercises.length; i++) ...[
          _ExerciseCard(
            key: ValueKey(
              '${session.exercises[i].slot}:'
              '${session.exercises[i].exercise.id}',
            ),
            onSwap: () => _swap(i),
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

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    super.key,
    required this.planned,
    required this.sets,
    required this.logging,
    required this.onChanged,
    required this.onDone,
    required this.onSwap,
  });

  final PlannedExercise planned;
  final List<_Set> sets;
  final bool logging;
  final VoidCallback onChanged;

  /// A set was ticked off.
  final VoidCallback onDone;

  final VoidCallback onSwap;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  /// Warm-up sets ticked off: not logged, they do not count as work.
  final Set<int> _warmed = {};

  @override
  Widget build(BuildContext context) {
    final planned = widget.planned;
    final sets = widget.sets;
    final logging = widget.logging;
    final onChanged = widget.onChanged;
    final onDone = widget.onDone;
    final exercise = planned.exercise;
    final kgStep = exercise.dumbbell
        ? 2.0
        : exercise.lower
        ? 5.0
        : 2.5;
    final warmUp = WarmUp.sets(planned, step: kgStep);
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
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: 'Swap ${exercise.name}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onSwap,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HaloColors.fill.resolveFrom(context),
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_2_circlepath,
                      size: 16,
                      color: HaloColors.labelOf(context),
                    ),
                  ),
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
          if (planned.swapped)
            Text(
              'Your choice',
              style: TextStyle(color: secondary, fontSize: 13),
            ),
          if (warmUp.isNotEmpty && !logging)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Warm-up: ${warmUp.map((w) => '${w.reps} × '
                    '${Format.decimal(w.kg)} kg').join(' · ')}',
                style: TextStyle(color: secondary, fontSize: 13),
              ),
            ),
          if (logging) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < warmUp.length; i++)
              _WarmUpSetRow(
                set: warmUp[i],
                done: _warmed.contains(i),
                onTap: () => setState(() {
                  HapticFeedback.selectionClick();
                  if (!_warmed.remove(i)) _warmed.add(i);
                }),
              ),
            for (var i = 0; i < sets.length; i++)
              _SetRow(
                index: i,
                set: sets[i],
                unit: seconds ? 's' : 'reps',
                step: seconds ? 5 : 1,
                kgStep: kgStep,
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

/// The general warm-up: a few minutes, each move ticked off.
class _WarmUpCard extends StatelessWidget {
  const _WarmUpCard({
    required this.moves,
    required this.done,
    required this.onToggle,
  });

  final List<WarmUpMove> moves;
  final Set<int> done;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final color = CupertinoColors.systemOrange.resolveFrom(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.flame, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Warm-Up',
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${done.length} of ${moves.length}',
                style: TextStyle(color: secondary, fontSize: 13),
              ),
            ],
          ),
          Text(
            'About 6 minutes, to get warm and loosen what is about to work.',
            style: TextStyle(color: secondary, fontSize: 14),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < moves.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onToggle(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      done.contains(i)
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 22,
                      color: done.contains(i) ? color : secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        moves[i].name,
                        style: TextStyle(
                          color: HaloColors.labelOf(context),
                          fontSize: 15,
                          decoration: done.contains(i)
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      moves[i].amount,
                      style: TextStyle(color: secondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A warm-up set: lighter, marked W, ticked off but never logged.
class _WarmUpSetRow extends StatelessWidget {
  const _WarmUpSetRow({
    required this.set,
    required this.done,
    required this.onTap,
  });

  final WarmUpSet set;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = CupertinoColors.systemOrange.resolveFrom(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              'W',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${set.reps} reps · ${Format.decimal(set.kg)} kg',
              style: TextStyle(
                color: secondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? color : color.withValues(alpha: 0.16),
              ),
              child: Icon(
                CupertinoIcons.checkmark_alt,
                size: 17,
                color: done ? const Color(0xFFFFFFFF) : color,
              ),
            ),
          ),
          const SizedBox(width: 3),
        ],
      ),
    );
  }
}
