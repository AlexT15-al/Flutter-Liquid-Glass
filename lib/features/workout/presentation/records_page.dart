import 'package:flutter/cupertino.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/records.dart';
import '../../../domain/training.dart';
import '../../../domain/workout.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_page.dart';
import 'workout_detail_page.dart';

/// Personal records: the bests of every kind of workout, and of every
/// exercise lifted.
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const RecordsPage());

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  Stream<List<WorkoutRecord>>? _workouts;
  Stream<List<SetLog>>? _sets;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _workouts ??= HaloScope.workoutsOf(context).watchRecent(100000);
    _sets ??= HaloScope.trainingOf(context).watchAll();
  }

  String _date(DateTime t) =>
      '${t.day} ${Format.monthName(t).substring(0, 3)} '
      '${t.year}';

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'Personal Records'),
      body: StreamBuilder<List<WorkoutRecord>>(
        stream: _workouts,
        initialData: const [],
        builder: (context, workoutSnapshot) => StreamBuilder<List<SetLog>>(
          stream: _sets,
          initialData: const [],
          builder: (context, setSnapshot) {
            final workouts = Records.workouts(
              workoutSnapshot.data ?? const [],
              Format.pace,
              Format.clock,
            );
            final strength = Records.strength(setSnapshot.data ?? const []);
            final types = workouts.keys.toList()
              ..sort((a, b) => a.index.compareTo(b.index));
            final exercises = strength.keys.toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            return ListView(
              padding: EdgeInsets.fromLTRB(
                HaloMetrics.cardPadding,
                HaloMetrics.topInset(context),
                HaloMetrics.cardPadding,
                HaloMetrics.bottomInset(context),
              ),
              children: [
                if (types.isEmpty && exercises.isEmpty)
                  const GroupCaption(
                    'Records appear here as you record workouts and finish '
                    'sessions from your training plan.',
                    footer: true,
                  ),
                for (final type in types) ...[
                  _Header(icon: type.icon, title: type.title),
                  GroupedCard(
                    children: [
                      for (final record in workouts[type]!)
                        GroupedRow(
                          title: record.title,
                          value: record.value,
                          onTap: record.workout == null
                              ? null
                              : () => Navigator.of(context).push(
                                  WorkoutDetailPage.route(record.workout!),
                                ),
                        ),
                    ],
                  ),
                  GroupCaption(
                    'Latest record ${_date(workouts[type]!.map((r) => r.date).reduce((a, b) => a.isAfter(b) ? a : b))}',
                    footer: true,
                  ),
                  const SizedBox(height: HaloMetrics.sectionTopGap - 8),
                ],
                if (exercises.isNotEmpty) ...[
                  const _Header(
                    icon: CupertinoIcons.flame_fill,
                    title: 'Strength',
                  ),
                  for (final exercise in exercises) ...[
                    GroupCaption(exercise.name),
                    GroupedCard(
                      children: [
                        for (final record in strength[exercise]!)
                          GroupedRow(title: record.title, value: record.value),
                      ],
                    ),
                    const SizedBox(height: HaloMetrics.cardGap + 4),
                  ],
                  const GroupCaption(
                    'The one rep max is estimated from your best set with '
                    'Epley\'s formula: weight × (1 + reps ÷ 30).',
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

class _Header extends StatelessWidget {
  const _Header({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, HaloMetrics.sectionTitleGap),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: HaloMetrics.sectionTitleSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
