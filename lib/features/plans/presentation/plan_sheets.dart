import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/meal_plan.dart';
import '../../../domain/training.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_sheet.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// The weekdays the meal plan keeps lenten.
Future<void> showFastingDaysSheet(
  BuildContext context,
  MealPlanSettings settings,
) async {
  final preferences = HaloScope.preferencesOf(context);
  final days = await showHaloSheet<Set<int>>(
    context,
    builder: (context, scroll) => _DaysSheet(
      controller: scroll,
      title: 'Fasting Days',
      initial: settings.fastingWeekdays,
      footer:
          'Lenten meals on these days: no meat, fish, dairy or eggs. '
          'Wednesday and Friday are the usual Orthodox fasting days.',
    ),
  );
  if (days != null) {
    await preferences.setMealPlan(settings.copyWith(fastingWeekdays: days));
  }
}

class _DaysSheet extends StatefulWidget {
  const _DaysSheet({
    required this.controller,
    required this.title,
    required this.initial,
    required this.footer,
  });

  final ScrollController controller;
  final String title;
  final Set<int> initial;
  final String footer;

  @override
  State<_DaysSheet> createState() => _DaysSheetState();
}

class _DaysSheetState extends State<_DaysSheet> {
  late final Set<int> _days = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: widget.title,
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(_days);
          },
        ),
      ),
      children: [
        GroupedCard(
          children: [
            for (var d = 1; d <= 7; d++)
              GroupedRow(
                title: _weekdays[d - 1],
                trailing: _days.contains(d)
                    ? Icon(CupertinoIcons.checkmark_alt, color: accent)
                    : const SizedBox(width: 24),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(
                    () => _days.contains(d) ? _days.remove(d) : _days.add(d),
                  );
                },
              ),
          ],
        ),
        GroupCaption(widget.footer, footer: true),
        const SizedBox(height: HaloMetrics.sheetBottomPadding),
      ],
    );
  }
}

/// Where, how experienced, and which days: the plan is built from these.
Future<void> showTrainingSetupSheet(
  BuildContext context,
  TrainingProfile current,
) async {
  final preferences = HaloScope.preferencesOf(context);
  final next = await showHaloSheet<TrainingProfile>(
    context,
    builder: (context, scroll) =>
        _SetupSheet(controller: scroll, initial: current),
  );
  if (next != null) await preferences.setTraining(next);
}

class _SetupSheet extends StatefulWidget {
  const _SetupSheet({required this.controller, required this.initial});

  final ScrollController controller;
  final TrainingProfile initial;

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  late TrainingProfile _profile = widget.initial;

  Widget _segments<T>({
    required List<T> values,
    required String Function(T) label,
    required T selected,
    required ValueChanged<T> onChanged,
  }) => HaloCard(
    padding: const EdgeInsets.all(12),
    child: GlassSegmentedControl(
      segments: [for (final v in values) GlassSegment(label: label(v))],
      selectedIndex: values.indexOf(selected),
      onSegmentSelected: (i) => onChanged(values[i]),
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
  );

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final count = _profile.weekdays.length;
    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: 'Training',
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: _profile.weekdays.isEmpty
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(_profile);
                },
        ),
      ),
      children: [
        const GroupCaption('Where'),
        _segments(
          values: TrainingPlace.values,
          label: (p) => p.title,
          selected: _profile.place,
          onChanged: (p) =>
              setState(() => _profile = _profile.copyWith(place: p)),
        ),
        const GroupCaption(
          'At home everything is bodyweight: a table, a chair and a little '
          'floor space.',
          footer: true,
        ),
        const SizedBox(height: HaloMetrics.sectionTopGap),
        const GroupCaption('Experience'),
        _segments(
          values: TrainingLevel.values,
          label: (l) => l.title,
          selected: _profile.level,
          onChanged: (l) =>
              setState(() => _profile = _profile.copyWith(level: l)),
        ),
        const SizedBox(height: HaloMetrics.sectionTopGap),
        const GroupCaption('Sessions a Week'),
        _segments(
          values: const [2, 3, 4, 5],
          label: (n) => '$n',
          selected: count.clamp(2, 5),
          onChanged: (n) => setState(
            () => _profile = _profile.copyWith(
              weekdays: TrainingProfile.defaultDays(n),
            ),
          ),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        GroupedCard(
          children: [
            for (var d = 1; d <= 7; d++)
              GroupedRow(
                title: _weekdays[d - 1],
                trailing: _profile.weekdays.contains(d)
                    ? Icon(CupertinoIcons.checkmark_alt, color: accent)
                    : const SizedBox(width: 24),
                onTap: () {
                  HapticFeedback.selectionClick();
                  final days = {..._profile.weekdays};
                  days.contains(d) ? days.remove(d) : days.add(d);
                  setState(() => _profile = _profile.copyWith(weekdays: days));
                },
              ),
          ],
        ),
        const SizedBox(height: HaloMetrics.sheetBottomPadding),
      ],
    );
  }
}
