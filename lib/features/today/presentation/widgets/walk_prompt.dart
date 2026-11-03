import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';

import '../../../../app/halo_scope.dart';
import '../../../../app/theme/halo_colors.dart';
import '../../../../app/theme/halo_metrics.dart';
import '../../../../data/activity/activity_store.dart';
import '../../../../domain/walk_detection.dart';
import '../../../../domain/workout.dart';
import '../../../../shared/format.dart';
import '../../../../shared/widgets/halo_card.dart';

/// Walks found in today's steps, each offered to be saved as a workout or
/// dismissed. Nothing at all while there are none.
class WalkPrompt extends StatefulWidget {
  const WalkPrompt({super.key, required this.activity});

  final ActivityStore activity;

  @override
  State<WalkPrompt> createState() => _WalkPromptState();
}

class _WalkPromptState extends State<WalkPrompt> {
  Stream<bool>? _on;
  Stream<int>? _minutes;
  Stream<Set<int>>? _dismissed;

  /// Saved or dismissed here, gone before the streams catch up.
  final Set<int> _handled = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final preferences = HaloScope.preferencesOf(context);
    _on ??= preferences.watchDetectWalks();
    _minutes ??= preferences.watchDetectWalkMinutes();
    _dismissed ??= preferences.watchDismissedWalks();
  }

  Future<void> _save(DetectedWalk walk) async {
    HapticFeedback.mediumImpact();
    setState(() => _handled.add(walk.key));
    final profile = widget.activity.profile;
    const type = WorkoutType.outdoorWalk;
    final hours = walk.length.inSeconds / Duration.secondsPerHour;
    await HaloScope.workoutsOf(context).save(
      WorkoutRecord(
        type: type,
        start: walk.start,
        end: walk.end,
        activeDuration: walk.length,
        distanceKm: walk.steps * profile.walkingStrideMeters / 1000,
        activeKcal: (type.met - 1) * profile.weightKg * hours,
        steps: walk.steps,
      ),
    );
  }

  Future<void> _dismiss(DetectedWalk walk) async {
    HapticFeedback.selectionClick();
    setState(() => _handled.add(walk.key));
    await HaloScope.preferencesOf(context).dismissWalk(walk.key);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _on,
      initialData: true,
      builder: (context, on) {
        if (on.data == false) return const SizedBox.shrink();
        return StreamBuilder<int>(
          stream: _minutes,
          initialData: 10,
          builder: (context, minutes) => StreamBuilder<Set<int>>(
            stream: _dismissed,
            initialData: const {},
            builder: (context, dismissed) => ListenableBuilder(
              listenable: widget.activity,
              builder: (context, _) {
                final now = DateTime.now();
                final walks = WalkDetector.detect(
                  widget.activity.spans
                      .where(
                        (s) =>
                            now.difference(s.end) < const Duration(hours: 24),
                      )
                      .toList(),
                  minimum: Duration(minutes: minutes.data ?? 10),
                  now: now,
                  workouts: widget.activity.workoutRecords,
                  dismissed: {...?dismissed.data, ..._handled},
                );
                if (walks.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    for (final walk in walks.reversed.take(2)) ...[
                      const SizedBox(height: HaloMetrics.cardGap),
                      _WalkCard(
                        walk: walk,
                        onSave: () => _save(walk),
                        onDismiss: () => _dismiss(walk),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _WalkCard extends StatelessWidget {
  const _WalkCard({
    required this.walk,
    required this.onSave,
    required this.onDismiss,
  });

  final DetectedWalk walk;
  final VoidCallback onSave;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    final day = Format.relativeDay(walk.start);
    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.18),
                ),
                child: Icon(
                  Icons.directions_walk_rounded,
                  size: 24,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Walk Detected',
                      style: TextStyle(
                        color: HaloColors.labelOf(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${day == 'Today' ? '' : '$day, '}'
                      '${Format.timeOfDay(walk.start)}–'
                      '${Format.timeOfDay(walk.end)} · '
                      '${Format.durationWords(walk.length)} · '
                      '${Format.integer(walk.steps)} steps',
                      style: TextStyle(color: secondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Button(
                  label: 'Save as Workout',
                  filled: true,
                  onTap: onSave,
                ),
              ),
              const SizedBox(width: 10),
              _Button(label: 'Dismiss', onTap: onDismiss),
            ],
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: filled ? accent : HaloColors.fill.resolveFrom(context),
            shape: const StadiumBorder(),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: filled
                  ? HaloColors.onAccent.resolveFrom(context)
                  : HaloColors.labelOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
