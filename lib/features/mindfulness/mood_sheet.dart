import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/halo_scope.dart';
import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_metrics.dart';
import '../../domain/mindfulness.dart';
import '../../shared/widgets/grouped_list.dart';
import '../../shared/widgets/halo_card.dart';
import '../../shared/widgets/halo_sheet.dart';
import 'mindful_shared.dart';

/// How do you feel? A place on the scale, then the feelings and what it is
/// about, all optional but the first.
Future<void> showMoodSheet(BuildContext context) async {
  final repository = HaloScope.mindfulnessOf(context);
  final mood = await showHaloSheet<MoodEntry>(
    context,
    builder: (context, scroll) => _MoodSheet(controller: scroll),
  );
  if (mood != null) await repository.addMood(mood);
}

class _MoodSheet extends StatefulWidget {
  const _MoodSheet({required this.controller});

  final ScrollController controller;

  @override
  State<_MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState extends State<_MoodSheet> {
  double _valence = 3;
  final Set<String> _feelings = {};
  final Set<String> _contexts = {};

  int get _level => _valence.round();

  @override
  Widget build(BuildContext context) {
    final color = moodColor(_level);
    final feelings = Mood.feelingsFor(_level);

    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: 'How Do You Feel?',
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(
              MoodEntry(
                time: DateTime.now(),
                valence: _level,
                feelings: {..._feelings.where(feelings.contains)},
                contexts: {..._contexts},
              ),
            );
          },
        ),
      ),
      children: [
        HaloCard(
          child: Column(
            children: [
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.lerp(color, const Color(0xFFFFFFFF), 0.35)!,
                      color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Mood.labels[_level],
                style: TextStyle(
                  color: HaloColors.labelOf(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              CupertinoSlider(
                value: _valence,
                max: 6,
                divisions: 6,
                activeColor: color,
                onChanged: (v) {
                  if (v.round() != _level) HapticFeedback.selectionClick();
                  setState(() => _valence = v);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final t in const ['Very Unpleasant', 'Very Pleasant'])
                    Text(
                      t.toUpperCase(),
                      style: TextStyle(
                        color: HaloColors.secondaryLabelOf(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: HaloMetrics.sectionTopGap),
        const GroupCaption('What Describes This Feeling?'),
        _Chips(
          options: feelings,
          selected: _feelings,
          color: color,
          onToggle: (f) => setState(
            () =>
                _feelings.contains(f) ? _feelings.remove(f) : _feelings.add(f),
          ),
        ),
        const SizedBox(height: HaloMetrics.sectionTopGap),
        const GroupCaption('What’s Having the Biggest Impact?'),
        _Chips(
          options: Mood.contexts,
          selected: _contexts,
          color: color,
          onToggle: (c) => setState(
            () =>
                _contexts.contains(c) ? _contexts.remove(c) : _contexts.add(c),
          ),
        ),
        const SizedBox(height: HaloMetrics.sheetBottomPadding),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.options,
    required this.selected,
    required this.color,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final Color color;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggle(o);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: ShapeDecoration(
                color: selected.contains(o)
                    ? color
                    : HaloColors.card.resolveFrom(context),
                shape: const StadiumBorder(),
              ),
              child: Text(
                o,
                style: TextStyle(
                  color: selected.contains(o)
                      ? const Color(0xFF000000)
                      : HaloColors.labelOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
