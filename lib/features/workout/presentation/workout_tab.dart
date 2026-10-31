import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/workout.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/large_title.dart';
import 'workout_detail_page.dart';
import 'workout_setup_sheet.dart';

/// The Workout tab: this week at a glance, every way to start, and what was
/// done lately.
class WorkoutTab extends StatefulWidget {
  const WorkoutTab({super.key, required this.titleController});

  /// Drives the large title in the content and the small one in the bar.
  final GlassLargeTitleController titleController;

  @override
  State<WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<WorkoutTab> {
  Stream<List<WorkoutRecord>>? _week;
  Stream<List<WorkoutRecord>>? _recent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = HaloScope.workoutsOf(context);
    final now = DateTime.now();
    // The week starts on Monday, as the week strip on Activity does.
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    _week ??= repository.watchBetween(
      monday,
      DateTime(monday.year, monday.month, monday.day + 7),
    );
    _recent ??= repository.watchRecent(5);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.titleController.scrollController,
      slivers: [
        ...largeTitleSlivers(
          context,
          title: 'Workout',
          controller: widget.titleController,
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: HaloMetrics.cardPadding,
          ),
          sliver: SliverList.list(
            children: [
              StreamBuilder<List<WorkoutRecord>>(
                stream: _week,
                initialData: const [],
                builder: (context, snapshot) =>
                    _WeekCard(workouts: snapshot.data ?? const []),
              ),
              const _SectionTitle('Start a Workout'),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: HaloMetrics.cardPadding,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: HaloMetrics.cardGap,
              crossAxisSpacing: HaloMetrics.cardGap,
              mainAxisExtent: 128,
            ),
            itemCount: WorkoutType.values.length,
            itemBuilder: (context, index) {
              final type = WorkoutType.values[index];
              return _TypeTile(
                type: type,
                onTap: () => showWorkoutSetup(context, type),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: HaloMetrics.cardPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: StreamBuilder<List<WorkoutRecord>>(
              stream: _recent,
              initialData: const [],
              builder: (context, snapshot) {
                final recent = snapshot.data ?? const [];
                if (recent.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle('Recent'),
                    GroupedCard(
                      children: [
                        for (final workout in recent)
                          GroupedRow(
                            leading: _TypeBadge(type: workout.type, size: 32),
                            title: workout.type.title,
                            value: Format.relativeDay(workout.start),
                            onTap: () => Navigator.of(context).push(
                              WorkoutDetailPage.route(workout),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: HaloMetrics.bottomInset(context)),
        ),
      ],
    );
  }
}

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

/// Workouts, time and energy so far this week.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.workouts});

  final List<WorkoutRecord> workouts;

  @override
  Widget build(BuildContext context) {
    final time = workouts.fold<Duration>(
      Duration.zero,
      (sum, w) => sum + w.activeDuration,
    );
    final kcal = workouts.fold<double>(0, (sum, w) => sum + w.activeKcal);

    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                value: '${workouts.length}',
                label: workouts.length == 1 ? 'WORKOUT' : 'WORKOUTS',
                color: HaloColors.accent.resolveFrom(context),
              ),
              _Stat(
                value: Format.durationWords(time),
                label: 'TIME',
                color: HaloColors.activeHours.resolveFrom(context),
              ),
              _Stat(
                value: Format.integer(kcal),
                label: 'KCAL',
                color: HaloColors.move.resolveFrom(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.onTap});

  final WorkoutType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HaloCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeBadge(type: type, size: 44),
          const Spacer(),
          Text(
            type.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Open Goal',
            style: TextStyle(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// A workout's glyph in an accent-tinted circle.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.size});

  final WorkoutType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.18),
      ),
      child: Icon(type.icon, size: size * 0.56, color: accent),
    );
  }
}
