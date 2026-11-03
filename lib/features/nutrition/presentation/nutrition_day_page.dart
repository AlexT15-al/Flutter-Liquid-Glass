import 'package:flutter/cupertino.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/nutrition.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/day_bars.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import 'nutrition_tab.dart';

/// Nutrition, day by day: calories for every day back three months, and
/// any day in full, its meals there to change, remove or add to.
class NutritionDayPage extends StatefulWidget {
  const NutritionDayPage({super.key, this.day});

  /// The day shown first; today when null.
  final DateTime? day;

  static Route<void> route({DateTime? day}) =>
      CupertinoPageRoute<void>(builder: (_) => NutritionDayPage(day: day));

  @override
  State<NutritionDayPage> createState() => _NutritionDayPageState();
}

class _NutritionDayPageState extends State<NutritionDayPage> {
  static const _days = 90;

  late final DateTime _today = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }();
  late DateTime _day = () {
    final d = widget.day ?? _today;
    return DateTime(d.year, d.month, d.day);
  }();

  Stream<List<FoodEntry>>? _all;
  Stream<WeightGoal>? _goal;
  final _scroll = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _all ??= HaloScope.nutritionOf(context).watchFoodBetween(
      DateTime(_today.year, _today.month, _today.day - _days + 1),
      DateTime(_today.year, _today.month, _today.day + 1),
    );
    _goal ??= HaloScope.preferencesOf(context).watchWeightGoal();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static int _back(DateTime from, DateTime day) => DateTime.utc(
    from.year,
    from.month,
    from.day,
  ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;

  @override
  Widget build(BuildContext context) {
    final activity = HaloScope.activityOf(context);
    final color = HaloColors.nutrition.resolveFrom(context);

    return HaloPage(
      appBar: haloBar(context, title: 'Nutrition'),
      body: StreamBuilder<WeightGoal>(
        stream: _goal,
        initialData: const WeightGoal(),
        builder: (context, goal) => StreamBuilder<List<FoodEntry>>(
          stream: _all,
          initialData: const [],
          builder: (context, snapshot) {
            final all = snapshot.data ?? const [];
            final targets = NutritionTargets.of(
              activity.profile,
              goal.data ?? const WeightGoal(),
              today: _day,
            );
            final perDay = List.filled(_days, 0.0);
            final byDay = <DateTime, List<FoodEntry>>{};
            for (final e in all) {
              final day = DateTime(e.time.year, e.time.month, e.time.day);
              (byDay[day] ??= []).add(e);
              final back = _back(_today, day);
              if (back >= 0 && back < _days) {
                perDay[_days - 1 - back] += e.kcal ?? 0;
              }
            }
            final food = byDay[_day] ?? const <FoodEntry>[];
            final logged = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

            return ListView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                HaloMetrics.cardPadding,
                HaloMetrics.topInset(context),
                HaloMetrics.cardPadding,
                HaloMetrics.bottomInset(context),
              ),
              children: [
                HaloCard(
                  child: DayBars(
                    // Rebuilt on a day picked from the history, to show it.
                    key: ValueKey(_day),
                    values: perDay,
                    lastDay: _today,
                    color: color,
                    goal: targets.kcal.toDouble(),
                    goalIsTarget: false,
                    describe: (v) =>
                        v <= 0 ? 'Nothing logged' : '${Format.integer(v)} kcal',
                    initial: _back(_today, _day),
                    onSelect: (day) => setState(() => _day = day),
                  ),
                ),
                const SizedBox(height: HaloMetrics.sectionTopGap),
                GroupCaption(Format.relativeDay(_day)),
                CaloriesCard(
                  targets: targets,
                  food: food,
                  exercise: activity.summaryFor(_day).activeKcal,
                ),
                for (final meal in Meal.values)
                  MealSection(
                    meal: meal,
                    day: _day,
                    entries: [
                      for (final e in food)
                        if (e.meal == meal) e,
                    ],
                  ),
                if (logged.isNotEmpty) ...[
                  const SizedBox(height: HaloMetrics.sectionTopGap),
                  const GroupCaption('History'),
                  GroupedCard(
                    children: [
                      for (final day in logged.take(30))
                        GroupedRow(
                          title: Format.relativeDay(day),
                          value: () {
                            final entries = byDay[day]!;
                            final kcal = entries.fold<double>(
                              0,
                              (t, e) => t + (e.kcal ?? 0),
                            );
                            final protein = entries.fold<double>(
                              0,
                              (t, e) => t + (e.protein ?? 0),
                            );
                            return '${Format.integer(kcal)} kcal · '
                                '${protein.round()} g';
                          }(),
                          onTap: () {
                            setState(() => _day = day);
                            _scroll.animateTo(
                              0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                    ],
                  ),
                  const GroupCaption(
                    'Tap a day to see it in full. Tap any food to change '
                    'how much, or to remove it.',
                    footer: true,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
