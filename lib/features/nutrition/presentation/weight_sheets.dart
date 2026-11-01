import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/body_profile.dart';
import '../../../domain/nutrition.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/bmi_gauge.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_sheet.dart';

/// A weigh-in: logged, and the profile's weight with it, so everything
/// worked out from the weight (energy, calories, plans) follows.
Future<void> showLogWeightSheet(
  BuildContext context,
  BodyProfile profile,
) async {
  final preferences = HaloScope.preferencesOf(context);
  final nutrition = HaloScope.nutritionOf(context);
  final kg = await showHaloSheet<double>(
    context,
    builder: (context, scroll) => _KgSheet(
      controller: scroll,
      title: 'Log Weight',
      initial: profile.weightKg,
    ),
  );
  if (kg == null) return;
  await nutrition.addWeight(DateTime.now(), kg);
  await preferences.setProfile(profile.copyWith(weightKg: kg));
}

class _KgSheet extends StatefulWidget {
  const _KgSheet({
    required this.controller,
    required this.title,
    required this.initial,
  });

  final ScrollController controller;
  final String title;
  final double initial;

  @override
  State<_KgSheet> createState() => _KgSheetState();
}

class _KgSheetState extends State<_KgSheet> {
  late double _kg = (widget.initial * 10).round() / 10;

  @override
  Widget build(BuildContext context) {
    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: widget.title,
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(_kg);
          },
        ),
      ),
      children: [
        HaloCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: KgWheel(value: _kg, onChanged: (v) => setState(() => _kg = v)),
        ),
        const SizedBox(height: HaloMetrics.sheetBottomPadding),
      ],
    );
  }
}

/// Kilograms on two wheels, whole and tenths.
class KgWheel extends StatefulWidget {
  const KgWheel({super.key, required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  static const min = 30;
  static const max = 250;

  @override
  State<KgWheel> createState() => _KgWheelState();
}

class _KgWheelState extends State<KgWheel> {
  late int _whole = widget.value.floor().clamp(KgWheel.min, KgWheel.max);
  late int _tenth = ((widget.value - widget.value.floor()) * 10).round() % 10;

  late final FixedExtentScrollController _wholeScroll =
      FixedExtentScrollController(initialItem: _whole - KgWheel.min);
  late final FixedExtentScrollController _tenthScroll =
      FixedExtentScrollController(initialItem: _tenth);

  @override
  void dispose() {
    _wholeScroll.dispose();
    _tenthScroll.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_whole + _tenth / 10);

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: HaloColors.labelOf(context),
      fontSize: 22,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: CupertinoPicker(
              scrollController: _wholeScroll,
              itemExtent: 38,
              onSelectedItemChanged: (i) {
                _whole = KgWheel.min + i;
                _emit();
              },
              children: [
                for (var k = KgWheel.min; k <= KgWheel.max; k++)
                  Center(child: Text('$k', style: style)),
              ],
            ),
          ),
          Text('.', style: style),
          SizedBox(
            width: 70,
            child: CupertinoPicker(
              scrollController: _tenthScroll,
              itemExtent: 38,
              onSelectedItemChanged: (i) {
                _tenth = i;
                _emit();
              },
              children: [
                for (var t = 0; t < 10; t++)
                  Center(child: Text('$t', style: style)),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'kg',
              style: style.copyWith(
                color: HaloColors.secondaryLabelOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The target weight and how fast to get there, with what that means for
/// each day's calories.
Future<void> showWeightGoalSheet(
  BuildContext context,
  BodyProfile profile,
  WeightGoal goal,
) async {
  final preferences = HaloScope.preferencesOf(context);
  final next = await showHaloSheet<WeightGoal>(
    context,
    builder: (context, scroll) =>
        _GoalSheet(controller: scroll, profile: profile, goal: goal),
  );
  if (next != null) await preferences.setWeightGoal(next);
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({
    required this.controller,
    required this.profile,
    required this.goal,
  });

  final ScrollController controller;
  final BodyProfile profile;
  final WeightGoal goal;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late double _target = widget.goal.targetKg ?? widget.profile.weightKg;
  late WeightPace _pace = widget.goal.pace;

  WeightGoal get _goal => WeightGoal(targetKg: _target, pace: _pace);

  @override
  Widget build(BuildContext context) {
    final targets = NutritionTargets.of(
      widget.profile,
      _goal,
      today: DateTime.now(),
    );
    final weeks = NutritionTargets.weeksTo(widget.profile, _goal);
    final diff = _target - widget.profile.weightKg;
    final what = diff.abs() < 0.5
        ? 'Keep your weight'
        : diff < 0
        ? 'Lose ${Format.decimal(-diff)} kg'
        : 'Gain ${Format.decimal(diff)} kg';

    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: 'Target Weight',
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(_goal);
          },
        ),
      ),
      children: [
        HaloCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: KgWheel(
            value: _target,
            onChanged: (v) => setState(() => _target = v),
          ),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        HaloCard(
          padding: const EdgeInsets.all(12),
          child: GlassSegmentedControl(
            segments: [
              for (final p in WeightPace.values) GlassSegment(label: p.title),
            ],
            selectedIndex: _pace.index,
            onSegmentSelected: (i) =>
                setState(() => _pace = WeightPace.values[i]),
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
            unselectedTextStyle: DefaultTextStyle.of(context).style.copyWith(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        GroupedCard(
          children: [
            GroupedRow(title: 'Goal', value: what),
            BmiRow(
              bmi: widget.profile.bmi,
              target: Bmi.of(_target, widget.profile.heightCm),
            ),
            GroupedRow(
              title: 'Pace',
              value: '${Format.decimal(_pace.kgPerWeek)} kg a week',
            ),
            if (weeks != null && weeks > 0)
              GroupedRow(title: 'Reached In', value: 'About $weeks weeks'),
            GroupedRow(
              title: 'Daily Calories',
              value: '${Format.integer(targets.kcal)} kcal',
            ),
          ],
        ),
        if (Bmi.of(_target, widget.profile.heightCm) < BmiCategory.healthy.from)
          GroupCaption(
            'This target is below a healthy weight for your height '
            '(${healthyRangeText(widget.profile.heightCm)}). Aim within the '
            'range, or talk to a doctor first.',
            footer: true,
          ),
        GroupCaption(
          'A healthy weight for ${widget.profile.heightCm.round()} cm is '
          '${healthyRangeText(widget.profile.heightCm)}. '
          'Calories are worked out from your profile; half of what the rings '
          'measure is added each day as you move, since without a heart rate '
          'it is an estimate. Protein is 1.6 g per kg, or 1.8 g per kg of '
          'your target weight while losing. Plans follow this target.',
          footer: true,
        ),
        const SizedBox(height: HaloMetrics.sheetBottomPadding),
      ],
    );
  }
}
