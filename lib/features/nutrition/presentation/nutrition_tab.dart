import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../app/theme/halo_motion.dart';
import '../../../domain/body_profile.dart';
import '../../../domain/nutrition.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/bmi_gauge.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/large_title.dart';
import '../../../shared/widgets/progress_bar.dart';
import 'add_food_sheet.dart';
import 'nutrition_day_page.dart';
import 'weight_sheets.dart';

/// The Nutrition tab: what is left to eat today, the meals, water, and the
/// way to the target weight.
class NutritionTab extends StatefulWidget {
  const NutritionTab({super.key, required this.titleController});

  final GlassLargeTitleController titleController;

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  Stream<List<FoodEntry>>? _food;
  Stream<List<(int, int)>>? _water;
  Stream<WeightGoal>? _goal;
  DateTime? _day;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_day != today) {
      _day = today;
      final nutrition = HaloScope.nutritionOf(context);
      _food = nutrition.watchFoodOn(today);
      _water = nutrition.watchWaterOn(today);
    }
    _goal ??= HaloScope.preferencesOf(context).watchWeightGoal();
  }

  @override
  Widget build(BuildContext context) {
    final activity = HaloScope.activityOf(context);

    return ListenableBuilder(
      listenable: activity,
      builder: (context, _) => StreamBuilder<WeightGoal>(
        stream: _goal,
        initialData: const WeightGoal(),
        builder: (context, goalSnapshot) => StreamBuilder<List<FoodEntry>>(
          stream: _food,
          initialData: const [],
          builder: (context, foodSnapshot) => StreamBuilder<List<(int, int)>>(
            stream: _water,
            initialData: const [],
            builder: (context, waterSnapshot) => _build(
              context,
              profile: activity.profile,
              exercise: activity.today.activeKcal,
              goal: goalSnapshot.data ?? const WeightGoal(),
              food: foodSnapshot.data ?? const [],
              water: waterSnapshot.data ?? const [],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build(
    BuildContext context, {
    required BodyProfile profile,
    required double exercise,
    required WeightGoal goal,
    required List<FoodEntry> food,
    required List<(int, int)> water,
  }) {
    final targets = NutritionTargets.of(profile, goal, today: DateTime.now());

    return CustomScrollView(
      controller: widget.titleController.scrollController,
      slivers: [
        ...largeTitleSlivers(
          context,
          title: 'Nutrition',
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
              CaloriesCard(targets: targets, food: food, exercise: exercise),
              const SizedBox(height: HaloMetrics.cardGap),
              GroupedCard(
                children: [
                  GroupedRow(
                    leading: Icon(
                      CupertinoIcons.calendar,
                      size: 22,
                      color: HaloColors.nutrition.resolveFrom(context),
                    ),
                    title: 'History',
                    onTap: () =>
                        Navigator.of(context).push(NutritionDayPage.route()),
                  ),
                ],
              ),
              for (final meal in Meal.values)
                MealSection(
                  meal: meal,
                  entries: [
                    for (final e in food)
                      if (e.meal == meal) e,
                  ],
                ),
              const _SectionTitle('Water'),
              _WaterCard(water: water, target: targets.waterMl),
              const _SectionTitle('Weight'),
              _WeightCard(profile: profile, goal: goal, targets: targets),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        4,
        HaloMetrics.sectionTopGap,
        4,
        HaloMetrics.sectionTitleGap,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: HaloColors.labelOf(context),
                fontSize: HaloMetrics.sectionTitleSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                color: HaloColors.secondaryLabelOf(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

/// Calories left today: the goal, less what was eaten, plus what the rings
/// say was burned on top of an ordinary day. And the three macros.
class CaloriesCard extends StatelessWidget {
  const CaloriesCard({
    super.key,
    required this.targets,
    required this.food,
    required this.exercise,
  });

  final NutritionTargets targets;
  final List<FoodEntry> food;
  final double exercise;

  @override
  Widget build(BuildContext context) {
    double sum(double? Function(FoodEntry) of) =>
        food.fold(0, (total, e) => total + (of(e) ?? 0));
    final eaten = sum((e) => e.kcal);
    final budget = targets.budget(exercise);
    final earned = exercise * NutritionTargets.exerciseShare;
    final left = budget - eaten;
    final color = HaloColors.nutrition.resolveFrom(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    final label = HaloColors.labelOf(context);

    Widget line(String title, String value, {Color? valueColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: secondary, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? label,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return HaloCard(
      child: Column(
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 124,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    end: budget <= 0 ? 0 : (eaten / budget).clamp(0.0, 1.0),
                  ),
                  duration: HaloMotion.of(
                    context,
                    const Duration(milliseconds: 800),
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => CustomPaint(
                    painter: _Ring(
                      value: value,
                      color: left < 0
                          ? CupertinoColors.systemOrange.resolveFrom(context)
                          : color,
                    ),
                    child: child,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Format.integer(left.abs()),
                          style: TextStyle(
                            color: label,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          left < 0 ? 'KCAL OVER' : 'KCAL LEFT',
                          style: TextStyle(
                            color: secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    line('Goal', Format.integer(targets.kcal)),
                    line('Food', '− ${Format.integer(eaten)}'),
                    line(
                      'Exercise',
                      '+ ${Format.integer(earned)}',
                      valueColor: HaloColors.move.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Macro(
                title: 'Protein',
                grams: sum((e) => e.protein),
                target: targets.protein,
                color: CupertinoColors.systemPink.resolveFrom(context),
              ),
              const SizedBox(width: 14),
              _Macro(
                title: 'Carbs',
                grams: sum((e) => e.carbs),
                target: targets.carbs,
                color: CupertinoColors.systemTeal.resolveFrom(context),
              ),
              const SizedBox(width: 14),
              _Macro(
                title: 'Fat',
                grams: sum((e) => e.fat),
                target: targets.fat,
                color: CupertinoColors.systemYellow.resolveFrom(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = HaloColors.ringTrack(color),
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Ring old) => old.value != value || old.color != color;
}

class _Macro extends StatelessWidget {
  const _Macro({
    required this.title,
    required this.grams,
    required this.target,
    required this.color,
  });

  final String title;
  final double grams;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
          const SizedBox(height: 5),
          ProgressBar(
            value: target <= 0 ? 0 : (grams / target).clamp(0.0, 1.0),
            color: color,
          ),
          const SizedBox(height: 5),
          Text(
            '${grams.round()} / $target g',
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// One meal: what was in it, and a row to add to it.
class MealSection extends StatelessWidget {
  const MealSection({
    super.key,
    required this.meal,
    required this.entries,
    this.day,
  });

  final Meal meal;
  final List<FoodEntry> entries;

  /// The day food is added to; today when null.
  final DateTime? day;

  @override
  Widget build(BuildContext context) {
    final kcal = entries.fold<double>(0, (t, e) => t + (e.kcal ?? 0));
    final accent = HaloColors.accent.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          meal.title,
          trailing: entries.isEmpty ? null : '${Format.integer(kcal)} kcal',
        ),
        GroupedCard(
          children: [
            for (final entry in entries)
              GroupedRow(
                title: entry.name,
                value: entry.kcal == null
                    ? '—'
                    : '${Format.integer(entry.kcal!)} kcal',
                onTap: () => showEditFoodSheet(context, entry),
              ),
            GroupedRow(
              title: 'Add Food',
              leading: Icon(
                CupertinoIcons.plus_circle_fill,
                color: accent,
                size: 22,
              ),
              onTap: () => showAddFoodSheet(context, meal: meal, day: day),
            ),
          ],
        ),
      ],
    );
  }
}

/// Glasses of water against the day's target, with − and + a glass.
class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.water, required this.target});

  final List<(int, int)> water;
  final int target;

  static const glass = 250;

  @override
  Widget build(BuildContext context) {
    final ml = water.fold<int>(0, (t, w) => t + w.$2);
    final color = HaloColors.hydration.resolveFrom(context);
    final glasses = (target / glass).ceil();
    final drunk = (ml / glass).floor();
    final nutrition = HaloScope.nutritionOf(context);

    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: Format.litres(ml),
                        style: TextStyle(
                          color: HaloColors.labelOf(context),
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: ' / ${Format.litres(target)} L',
                        style: TextStyle(
                          color: HaloColors.secondaryLabelOf(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _RoundButton(
                icon: CupertinoIcons.minus,
                color: color,
                label: 'Remove a glass',
                onTap: water.isEmpty
                    ? null
                    : () => nutrition.deleteWater(water.last.$1),
              ),
              const SizedBox(width: 10),
              _RoundButton(
                icon: CupertinoIcons.plus,
                color: color,
                label: 'Add a glass',
                onTap: () => nutrition.addWater(DateTime.now(), glass),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < math.max(glasses, drunk); i++)
                Icon(
                  CupertinoIcons.drop_fill,
                  size: 22,
                  color: i < drunk ? color : HaloColors.ringTrack(color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
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
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.35,
          duration: HaloMotion.of(context, HaloMotion.controlSwapDuration),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

/// Where the weight is, where it is going, and the calories that get it
/// there.
class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.profile,
    required this.goal,
    required this.targets,
  });

  final BodyProfile profile;
  final WeightGoal goal;
  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    final target = goal.targetKg;
    final weeks = NutritionTargets.weeksTo(profile, goal);
    return GroupedCard(
      children: [
        GroupedRow(
          title: 'Current',
          value: '${Format.decimal(profile.weightKg)} kg',
          onTap: () => showLogWeightSheet(context, profile),
        ),
        GroupedRow(
          title: 'Target',
          value: target == null ? 'Not Set' : '${Format.decimal(target)} kg',
          onTap: () => showWeightGoalSheet(context, profile, goal),
        ),
        BmiRow(
          bmi: profile.bmi,
          target: target == null ? null : Bmi.of(target, profile.heightCm),
        ),
        if (target != null && weeks != null && weeks > 0)
          GroupedRow(
            title: 'Reached In',
            value: weeks == 1 ? 'About a week' : 'About $weeks weeks',
          ),
        GroupedRow(
          title: 'Daily Calories',
          value: '${Format.integer(targets.kcal)} kcal',
        ),
      ],
    );
  }
}
