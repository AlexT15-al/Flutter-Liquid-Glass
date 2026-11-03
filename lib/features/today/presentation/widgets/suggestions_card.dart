import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

import '../../../../app/halo_scope.dart';
import '../../../../app/shell/halo_tab.dart';
import '../../../../app/shell/halo_tab_controller.dart';
import '../../../../app/theme/halo_colors.dart';
import '../../../../domain/body_profile.dart';
import '../../../../domain/coach.dart';
import '../../../../domain/mindfulness.dart';
import '../../../../domain/nutrition.dart';
import '../../../../domain/readiness.dart';
import '../../../../domain/sleep.dart';
import '../../../../domain/training.dart';
import '../../../../domain/workout.dart';
import '../../../../shared/widgets/halo_card.dart';
import '../../../mindfulness/breathe_page.dart';
import '../../../nutrition/presentation/nutrition_day_page.dart';
import '../../../nutrition/presentation/water_page.dart';
import '../../../sleep/presentation/sleep_page.dart';
import '../../../sleep/sleep_controller.dart';
import '../steps_page.dart';
import 'readiness_card.dart';

/// The glyph and colour of a suggestion.
(IconData, CupertinoDynamicColor) _style(SuggestionKind kind) => switch (kind) {
  SuggestionKind.sleep ||
  SuggestionKind.bedtime => (CupertinoIcons.bed_double_fill, HaloColors.sleep),
  SuggestionKind.readiness => (CupertinoIcons.bolt_fill, HaloColors.accent),
  SuggestionKind.training => (
    Icons.fitness_center_rounded,
    HaloColors.exercise,
  ),
  SuggestionKind.workout => (Icons.directions_run_rounded, HaloColors.exercise),
  SuggestionKind.steps => (Icons.directions_walk_rounded, HaloColors.steps),
  SuggestionKind.rings => (CupertinoIcons.circle_grid_hex, HaloColors.move),
  SuggestionKind.protein ||
  SuggestionKind.calories ||
  SuggestionKind.log => (CupertinoIcons.chart_pie_fill, HaloColors.nutrition),
  SuggestionKind.water => (CupertinoIcons.drop_fill, HaloColors.hydration),
  SuggestionKind.weigh => (CupertinoIcons.person_fill, HaloColors.body),
  SuggestionKind.mind => (CupertinoIcons.wind, HaloColors.mindfulness),
};

/// For You: what is worth doing now, from everything Halo knows.
class SuggestionsCard extends StatefulWidget {
  const SuggestionsCard({super.key});

  @override
  State<SuggestionsCard> createState() => _SuggestionsCardState();
}

class _SuggestionsCardState extends State<SuggestionsCard> {
  final List<StreamSubscription<Object?>> _subs = [];
  bool _started = false;

  List<SleepNight> _nights = const [];
  SleepSchedule _schedule = const SleepSchedule();
  List<WorkoutRecord> _workouts = const [];
  List<WorkoutRecord> _lastWorkout = const [];
  TrainingProfile? _training;
  List<SetLog> _history = const [];
  WeightGoal _goal = const WeightGoal();
  List<FoodEntry> _food = const [];
  int _water = 0;
  DateTime? _lastWeigh;
  bool _mindful = false;
  List<MoodEntry> _moods = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final preferences = HaloScope.preferencesOf(context);
    final nutrition = HaloScope.nutritionOf(context);
    final workouts = HaloScope.workoutsOf(context);
    final mindfulness = HaloScope.mindfulnessOf(context);
    void on<T>(Stream<T> stream, void Function(T) set) =>
        _subs.add(stream.listen((v) => setState(() => set(v))));

    on(SleepScope.read(context).repository.watchNights(14), (v) => _nights = v);
    on(preferences.watchSleepSchedule(), (v) => _schedule = v);
    on(
      workouts.watchBetween(
        DateTime(today.year, today.month, today.day - 28),
        tomorrow,
      ),
      (v) => _workouts = v,
    );
    on(workouts.watchRecent(1), (v) => _lastWorkout = v);
    on(preferences.watchTraining(), (v) => _training = v);
    on(HaloScope.trainingOf(context).watchHistory(), (v) => _history = v);
    on(preferences.watchWeightGoal(), (v) => _goal = v);
    on(nutrition.watchFoodOn(today), (v) => _food = v);
    on(
      nutrition.watchWaterOn(today),
      (v) => _water = v.fold<int>(0, (t, w) => t + w.$2),
    );
    on(
      nutrition.watchWeights(limit: 1),
      (v) => _lastWeigh = v.isEmpty ? null : v.first.$1,
    );
    on(mindfulness.watchSessionsSince(today), (v) => _mindful = v.isNotEmpty);
    on(
      mindfulness.watchMoodsSince(
        DateTime(today.year, today.month, today.day - 1),
      ),
      (v) => _moods = v,
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  static int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  List<Suggestion> _suggestions(BuildContext context) {
    final activity = HaloScope.activityOf(context);
    final now = DateTime.now();
    final today = activity.today;
    final goals = activity.goals;
    final BodyProfile body = activity.profile;

    var streak = 0;
    for (final d in activity.lastDays(8).reversed.skip(1)) {
      if (d.steps >= goals.steps) {
        streak++;
      } else {
        break;
      }
    }
    final lastNight = _nights
        .where((n) => _daysBetween(n.morning, now) == 0)
        .fold<int>(0, (t, n) => t + n.asleep.inMinutes);
    final planned = _training == null
        ? null
        : TrainingPlanner.week(
            training: _training!,
            body: body,
            goal: _goal,
            history: _history,
          ).where((s) => s.weekday == now.weekday).firstOrNull;
    final targets = NutritionTargets.of(body, _goal, today: now);
    final moods = [..._moods]..sort((a, b) => b.time.compareTo(a.time));
    final last = _lastWorkout.firstOrNull;

    return Coach.suggest(
      CoachInputs(
        now: now,
        steps: today.steps,
        stepsGoal: goals.steps,
        stepStreak: streak,
        ringsClosed:
            today.activeKcal >= goals.moveKcal &&
            today.exerciseMinutes >= goals.exerciseMinutes &&
            today.activeHours >= goals.activeHours,
        lastNightMinutes: lastNight == 0 ? null : lastNight,
        sleepGoalMinutes: _schedule.goal.inMinutes,
        bedtimeMinutes: _schedule.bedtimeMinutes,
        readiness: Readiness.of(
          nights: _nights,
          workouts: _workouts,
          schedule: _schedule,
          now: now,
        )?.value,
        plannedTitle: planned?.title,
        plannedMinutes: planned?.length.inMinutes,
        workedOutToday: _workouts.any((w) => _daysBetween(w.start, now) == 0),
        daysSinceWorkout: last == null ? null : _daysBetween(last.start, now),
        foodLogged: _food.isNotEmpty,
        kcalEaten: _food.fold(0.0, (t, e) => t + (e.kcal ?? 0)),
        kcalBudget: targets.budget(today.activeKcal).toDouble(),
        proteinEaten: _food.fold(0.0, (t, e) => t + (e.protein ?? 0)),
        proteinTarget: targets.protein.toDouble(),
        waterMl: _water,
        waterGoalMl: targets.waterMl,
        daysSinceWeighIn: _lastWeigh == null
            ? null
            : _daysBetween(_lastWeigh!, now),
        mindfulToday: _mindful,
        recentMood: moods.firstOrNull?.valence,
      ),
    );
  }

  void _open(BuildContext context, SuggestionKind kind) {
    final navigator = Navigator.of(context);
    void tab(HaloTab t) => HaloTabScope.read(context).tab = t;
    switch (kind.route) {
      case 'sleep':
        navigator.push(SleepPage.route());
      case 'readiness':
        navigator.push(ReadinessPage.route());
      case 'steps':
        navigator.push(StepsPage.route());
      case 'water':
        navigator.push(WaterPage.route());
      case 'breathe':
        navigator.push(BreathePage.route());
      case 'nutrition':
        navigator.push(NutritionDayPage.route());
      case 'training':
        tab(HaloTab.plans);
      case 'workout':
        tab(HaloTab.workout);
      case 'weight':
        tab(HaloTab.nutrition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HaloScope.activityOf(context),
      builder: (context, _) {
        final suggestions = _suggestions(context);
        final accent = HaloColors.accent.resolveFrom(context);
        return HaloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.sparkles, size: 15, color: accent),
                  const SizedBox(width: 5),
                  Text(
                    'For You',
                    style: TextStyle(
                      color: accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (suggestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'All on track. Suggestions show up here as your day goes.',
                    style: TextStyle(
                      color: HaloColors.secondaryLabelOf(context),
                      fontSize: 15,
                    ),
                  ),
                )
              else
                for (final s in suggestions)
                  _Row(suggestion: s, onTap: () => _open(context, s.kind)),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.suggestion, required this.onTap});

  final Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, dynamicColor) = _style(suggestion.kind);
    final color = dynamicColor.resolveFrom(context);
    return Semantics(
      button: true,
      label: '${suggestion.title}. ${suggestion.detail}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.18),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      style: TextStyle(
                        color: HaloColors.labelOf(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      suggestion.detail,
                      style: TextStyle(
                        color: HaloColors.secondaryLabelOf(context),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: HaloColors.tertiaryLabelOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
