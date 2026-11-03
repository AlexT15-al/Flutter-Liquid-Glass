import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/body_profile.dart';
import '../../../domain/meal_plan.dart';
import '../../../domain/nutrition.dart';
import '../../../domain/training.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/glass_action_button.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/large_title.dart';
import 'plan_sheets.dart';
import 'session_page.dart';

/// Plans: the week's meals, sized to the calorie target and lenten on
/// fasting days, and the week's training, progressing from what was logged.
class PlansTab extends StatefulWidget {
  const PlansTab({super.key, required this.titleController});

  final GlassLargeTitleController titleController;

  @override
  State<PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<PlansTab> {
  int _view = 0;
  late DateTime _day = _today();

  Stream<MealPlanSettings>? _meals;
  Stream<TrainingProfile?>? _training;
  Stream<WeightGoal>? _goal;
  Stream<List<SetLog>>? _history;

  /// What was logged on the day shown, which the meals still to come adapt
  /// to; followed again when another day is picked.
  Stream<List<FoodEntry>>? _food;
  DateTime? _foodDay;

  Stream<List<FoodEntry>> _foodOn(DateTime day) {
    if (_food == null || _foodDay != day) {
      _foodDay = day;
      _food = HaloScope.nutritionOf(context).watchFoodOn(day);
    }
    return _food!;
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final preferences = HaloScope.preferencesOf(context);
    _meals ??= preferences.watchMealPlan();
    _training ??= preferences.watchTraining();
    _goal ??= preferences.watchWeightGoal();
    _history ??= HaloScope.trainingOf(context).watchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final activity = HaloScope.activityOf(context);
    return ListenableBuilder(
      listenable: activity,
      builder: (context, _) => StreamBuilder<WeightGoal>(
        stream: _goal,
        initialData: const WeightGoal(),
        builder: (context, goal) => StreamBuilder<MealPlanSettings>(
          stream: _meals,
          initialData: const MealPlanSettings(),
          builder: (context, meals) => StreamBuilder<TrainingProfile?>(
            stream: _training,
            builder: (context, training) => StreamBuilder<List<SetLog>>(
              stream: _history,
              initialData: const [],
              builder: (context, history) => _build(
                context,
                body: activity.profile,
                goal: goal.data ?? const WeightGoal(),
                meals: meals.data ?? const MealPlanSettings(),
                training: training.data,
                history: history.data ?? const [],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build(
    BuildContext context, {
    required BodyProfile body,
    required WeightGoal goal,
    required MealPlanSettings meals,
    required TrainingProfile? training,
    required List<SetLog> history,
  }) {
    return CustomScrollView(
      controller: widget.titleController.scrollController,
      slivers: [
        ...largeTitleSlivers(
          context,
          title: 'Plans',
          controller: widget.titleController,
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            HaloMetrics.cardPadding,
            0,
            HaloMetrics.cardPadding,
            HaloMetrics.bottomInset(context),
          ),
          sliver: SliverList.list(
            children: [
              GlassSegmentedControl(
                segments: const [
                  GlassSegment(label: 'Meals'),
                  GlassSegment(label: 'Training'),
                ],
                selectedIndex: _view,
                onSegmentSelected: (i) => setState(() => _view = i),
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
              const SizedBox(height: HaloMetrics.cardGap + 4),
              if (_view == 0)
                StreamBuilder<List<FoodEntry>>(
                  stream: _foodOn(_day),
                  initialData: const [],
                  builder: (context, food) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _mealsView(
                      context,
                      body,
                      goal,
                      meals,
                      food.data ?? const [],
                    ),
                  ),
                )
              else
                ..._trainingView(context, body, goal, training, history),
            ],
          ),
        ),
      ],
    );
  }

  // ── Meals ────────────────────────────────────────────────────────────────

  List<Widget> _mealsView(
    BuildContext context,
    BodyProfile body,
    WeightGoal goal,
    MealPlanSettings settings,
    List<FoodEntry> food,
  ) {
    final targets = NutritionTargets.of(body, goal, today: _day);
    final eaten = MealIntake.of(food);
    // Today counts the movement so far, as the Nutrition tab does.
    final budget = _day == _today()
        ? targets
              .budget(HaloScope.activityOf(context).today.activeKcal)
              .toDouble()
        : targets.kcal.toDouble();
    final plan = MealPlanner.day(
      _day,
      targets,
      settings,
      eaten: eaten,
      budget: budget,
    );
    final eatenKcal = eaten.values.fold<double>(0, (t, e) => t + e.kcal);
    final kcal = eatenKcal + plan.fold<double>(0, (t, m) => t + m.kcal);
    final protein =
        eaten.values.fold<double>(0, (t, e) => t + e.protein) +
        plan.fold<double>(0, (t, m) => t + m.protein);
    final over = eaten.isNotEmpty && kcal > budget * 1.05;
    // Room the plan leaves, when the meals left could not take it all.
    final spare = budget - kcal;
    final fasting = settings.fasting(_day);
    final preferences = HaloScope.preferencesOf(context);

    return [
      _WeekStrip(
        selected: _day,
        marked: settings.fasting,
        onSelected: (day) => setState(() => _day = day),
      ),
      const SizedBox(height: HaloMetrics.cardGap),
      HaloCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Format.relativeDay(_day),
                    style: TextStyle(
                      color: HaloColors.labelOf(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${Format.integer(kcal)} of ${Format.integer(budget)} kcal'
                    ' · ${protein.round()} g protein',
                    style: TextStyle(
                      color: HaloColors.secondaryLabelOf(context),
                      fontSize: 15,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (fasting) const _Badge('Fasting'),
          ],
        ),
      ),
      const SizedBox(height: HaloMetrics.cardGap),
      if (eaten.isNotEmpty)
        GroupCaption(
          over
              ? 'Over today’s calories already: the meals left are kept light.'
              : 'The meals left are resized to what you have eaten: '
                    '${Format.integer(eatenKcal)} kcal so far.'
                    '${spare > 150 ? ' About ${Format.integer(spare)} kcal '
                              'more is room for a snack, if hungry.' : ''}',
          footer: true,
        ),
      if (eaten.isNotEmpty) const SizedBox(height: 8),
      for (final meal in Meal.values)
        if (eaten[meal] case final intake?) ...[
          _LoggedMealCard(
            meal: meal,
            intake: intake,
            names: [
              for (final e in food)
                if (e.meal == meal) e.name,
            ],
          ),
          const SizedBox(height: HaloMetrics.cardGap),
        ] else if (plan.where((p) => p.meal == meal).firstOrNull
            case final planned?) ...[
          _PlannedMealCard(
            planned: planned,
            day: _day,
            onSwap: () {
              HapticFeedback.selectionClick();
              preferences.setMealPlan(settings.swapped(_day, planned.meal));
            },
          ),
          const SizedBox(height: HaloMetrics.cardGap),
        ],
      const SizedBox(height: HaloMetrics.sectionTopGap - HaloMetrics.cardGap),
      GroupedCard(
        children: [
          GroupedRow(
            title: 'Fasting Days',
            value: settings.fastingWeekdays.isEmpty
                ? 'None'
                : (settings.fastingWeekdays.toList()..sort())
                      .map(_weekdayShort)
                      .join(', '),
            onTap: () => showFastingDaysSheet(context, settings),
          ),
          GroupedRow(
            title: 'Lent',
            trailing: GlassSwitch(
              value: settings.lent,
              onChanged: (on) =>
                  preferences.setMealPlan(settings.copyWith(lent: on)),
              activeColor: HaloColors.exercise.resolveFrom(context),
              settings: HaloGlass.of(context),
              quality: HaloGlass.quality,
              useOwnLayer: true,
              semanticLabel: 'Lent',
            ),
          ),
        ],
      ),
      const GroupCaption(
        'Meals are sized to your daily calories and chosen to reach your '
        'protein, both following your target weight. On fasting days, and every day of Lent, only lenten dishes '
        'are planned. Swap any meal you do not fancy; tap + to log it.',
        footer: true,
      ),
    ];
  }

  // ── Training ─────────────────────────────────────────────────────────────

  List<Widget> _trainingView(
    BuildContext context,
    BodyProfile body,
    WeightGoal goal,
    TrainingProfile? training,
    List<SetLog> history,
  ) {
    if (training == null) {
      return [
        HaloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Training Plan',
                style: TextStyle(
                  color: HaloColors.labelOf(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A week of sessions for the gym or for home, that gets harder '
                'as you get stronger: loads and exercises move up from what '
                'you log, and follow your target weight.',
                style: TextStyle(
                  color: HaloColors.secondaryLabelOf(context),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: HaloMetrics.cardGap + 4),
        GlassActionButton(
          label: 'Set Up Training',
          icon: CupertinoIcons.sparkles,
          onTap: () => showTrainingSetupSheet(context, const TrainingProfile()),
        ),
      ];
    }

    final week = TrainingPlanner.week(
      training: training,
      body: body,
      goal: goal,
      history: history,
    );
    final today = _today();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final doneDays = {
      for (final s in history)
        if (!s.time.isBefore(monday))
          DateTime(s.time.year, s.time.month, s.time.day),
    };

    return [
      GroupedCard(
        children: [
          GroupedRow(
            title: 'Training',
            value:
                '${training.place.title} · ${training.level.title} · '
                '${training.weekdays.length} days',
            onTap: () => showTrainingSetupSheet(context, training),
          ),
        ],
      ),
      const _SectionTitle('This Week'),
      for (final session in week) ...[
        _SessionCard(
          session: session,
          date: monday.add(Duration(days: session.weekday - 1)),
          done: doneDays.contains(
            monday.add(Duration(days: session.weekday - 1)),
          ),
          today: today,
        ),
        const SizedBox(height: HaloMetrics.cardGap),
      ],
      const GroupCaption(
        'Loads go up when every set reaches the top of its range, and come '
        'down if two sessions fall short. At home, mastering an exercise moves '
        'you to a harder one.',
        footer: true,
      ),
    ];
  }
}

String _weekdayShort(int weekday) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        4,
        HaloMetrics.sectionTopGap,
        4,
        HaloMetrics.sectionTitleGap,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: HaloColors.labelOf(context),
          fontSize: HaloMetrics.sectionTitleSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = HaloColors.nutrition.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.16),
        shape: const StadiumBorder(),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// This week, Monday to Sunday: tap a day to see its meals. Fasting days
/// carry a dot.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selected,
    required this.marked,
    required this.onSelected,
  });

  final DateTime selected;
  final bool Function(DateTime day) marked;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final accent = HaloColors.accent.resolveFrom(context);
    final onAccent = HaloColors.onAccent.resolveFrom(context);
    final fastingColor = HaloColors.nutrition.resolveFrom(context);

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: () {
              final day = monday.add(Duration(days: i));
              final isSelected = day == selected;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(day);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: ShapeDecoration(
                      color: isSelected
                          ? accent
                          : HaloColors.card.resolveFrom(context),
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          Format.weekdayLetter(day),
                          style: TextStyle(
                            color: isSelected
                                ? onAccent
                                : HaloColors.secondaryLabelOf(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isSelected
                                ? onAccent
                                : day == today
                                ? accent
                                : HaloColors.labelOf(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: marked(day)
                                ? (isSelected ? onAccent : fastingColor)
                                : const Color(0x00000000),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }(),
          ),
      ],
    );
  }
}

/// A meal already eaten: what was logged, and what it came to.
class _LoggedMealCard extends StatelessWidget {
  const _LoggedMealCard({
    required this.meal,
    required this.intake,
    required this.names,
  });

  final Meal meal;
  final MealIntake intake;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final secondary = HaloColors.secondaryLabelOf(context);
    final accent = HaloColors.accent.resolveFrom(context);
    return HaloCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${meal.title.toUpperCase()} · EATEN',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  names.join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${Format.integer(intake.kcal)} kcal · '
                  '${intake.protein.round()} g protein',
                  style: TextStyle(color: secondary, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
            ),
            child: Icon(CupertinoIcons.checkmark, size: 18, color: accent),
          ),
        ],
      ),
    );
  }
}

/// A planned meal: what, how much, and buttons to swap it or log it.
class _PlannedMealCard extends StatefulWidget {
  const _PlannedMealCard({
    required this.planned,
    required this.day,
    required this.onSwap,
  });

  final PlannedMeal planned;
  final DateTime day;
  final VoidCallback onSwap;

  @override
  State<_PlannedMealCard> createState() => _PlannedMealCardState();
}

class _PlannedMealCardState extends State<_PlannedMealCard> {
  String? _logged;

  Future<void> _log() async {
    final planned = widget.planned;
    final now = DateTime.now();
    final day = widget.day;
    HapticFeedback.mediumImpact();
    await HaloScope.nutritionOf(context).addFood(
      planned.item.toEntry(
        // Logged on the planned day, at the time of day it is now.
        time: DateTime(day.year, day.month, day.day, now.hour, now.minute),
        meal: planned.meal,
        portions: planned.portions,
      ),
    );
    if (mounted) setState(() => _logged = planned.item.name);
  }

  @override
  Widget build(BuildContext context) {
    final planned = widget.planned;
    final logged = _logged == planned.item.name;
    final secondary = HaloColors.secondaryLabelOf(context);
    final accent = HaloColors.accent.resolveFrom(context);
    final portions = planned.portions == 1
        ? planned.item.portion
        : '${planned.portions == planned.portions.roundToDouble() ? planned.portions.round() : planned.portions} × ${planned.item.portion}';

    return HaloCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planned.meal.title.toUpperCase(),
                  style: TextStyle(
                    color: HaloColors.nutrition.resolveFrom(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  planned.item.name,
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$portions · ${Format.integer(planned.kcal)} kcal',
                  style: TextStyle(color: secondary, fontSize: 14),
                ),
              ],
            ),
          ),
          _IconCircle(
            icon: CupertinoIcons.arrow_2_circlepath,
            color: HaloColors.labelOf(context),
            label: 'Swap',
            onTap: widget.onSwap,
          ),
          const SizedBox(width: 8),
          _IconCircle(
            icon: logged ? CupertinoIcons.checkmark : CupertinoIcons.plus,
            color: accent,
            label: logged ? 'Logged' : 'Log',
            onTap: logged ? null : _log,
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/// A day of the training week: what it is, how long, done or not.
class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.date,
    required this.done,
    required this.today,
  });

  final PlannedSession session;
  final DateTime date;
  final bool done;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final isToday = date == today;
    final secondary = HaloColors.secondaryLabelOf(context);
    return HaloCard(
      onTap: () =>
          Navigator.of(context).push(SessionPage.route(session, date: date)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? accent : accent.withValues(alpha: 0.16),
            ),
            child: Icon(
              done ? CupertinoIcons.checkmark_alt : CupertinoIcons.flame_fill,
              color: done ? HaloColors.onAccent.resolveFrom(context) : accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : Format.longDate(date).split(',').first,
                  style: TextStyle(
                    color: isToday ? accent : secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  session.title,
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${session.exercises.length} exercises · about '
                  '${Format.durationWords(session.length)}',
                  style: TextStyle(color: secondary, fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 15,
            color: HaloColors.tertiaryLabelOf(context),
          ),
        ],
      ),
    );
  }
}
