import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/halo_colors.dart';
import '../../../domain/training.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_sheet.dart';

/// What the user picked in the swap sheet: an exercise, or the plan's own
/// choice back ([id] null).
class SwapChoice {
  const SwapChoice(this.id);

  final String? id;
}

/// The kit an exercise needs, in a word.
String equipmentOf(Exercise e) {
  if (e.place == TrainingPlace.home) return 'At home';
  if (!e.loaded) return 'Body weight';
  if (e.dumbbell) {
    return e.id.startsWith('kb_') ? 'Kettlebell' : 'Dumbbells';
  }
  final name = e.name.toLowerCase();
  if (name.contains('machine') ||
      name.contains('press') && name.contains('leg') ||
      name.contains('cable') ||
      name.contains('pulldown') ||
      name.contains('pushdown') ||
      name.contains('curl') && name.contains('leg') ||
      name.contains('extension') && name.contains('leg') ||
      name.contains('supported')) {
    return 'Machine';
  }
  return 'Barbell';
}

/// Other ways to train the same movement, for an exercise not liked or
/// without the kit for it.
Future<SwapChoice?> showSwapSheet(
  BuildContext context,
  PlannedExercise planned,
) => showHaloSheet<SwapChoice>(
  context,
  builder: (context, scroll) =>
      _SwapSheet(controller: scroll, planned: planned),
);

class _SwapSheet extends StatelessWidget {
  const _SwapSheet({required this.controller, required this.planned});

  final ScrollController controller;
  final PlannedExercise planned;

  @override
  Widget build(BuildContext context) {
    final current = planned.exercise;
    final options = ExerciseCatalog.alternatives(current);
    final secondary = HaloColors.secondaryLabelOf(context);

    void pick(String? id) {
      HapticFeedback.selectionClick();
      Navigator.of(context).pop(SwapChoice(id));
    }

    return HaloSheet(
      controller: controller,
      header: HaloSheetHeader(
        title: 'Swap Exercise',
        leading: SheetButton.close(context),
      ),
      children: [
        Text(
          'Instead of ${current.name}: the same movement, trained another '
          'way. The plan keeps your choice, and its loads progress from '
          'what you log.',
          textAlign: TextAlign.center,
          style: TextStyle(color: secondary, fontSize: 15),
        ),
        const SizedBox(height: 16),
        if (options.isEmpty)
          const GroupCaption('Nothing else trains this movement here.')
        else
          GroupedCard(
            children: [
              for (final e in options)
                GroupedRow(
                  title: e.name,
                  value: equipmentOf(e),
                  onTap: () => pick(e.id),
                ),
            ],
          ),
        if (planned.swapped) ...[
          const SizedBox(height: 16),
          GroupedCard(
            children: [
              GroupedRow(
                title: 'Back to the Plan’s Choice',
                onTap: () => pick(null),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
