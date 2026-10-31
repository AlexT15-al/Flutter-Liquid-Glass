import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app/halo_scope.dart';
import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_metrics.dart';
import '../../domain/mindfulness.dart';
import '../../shared/format.dart';
import '../../shared/widgets/grouped_list.dart';
import '../../shared/widgets/halo_card.dart';
import '../../shared/widgets/halo_page.dart';
import '../../shared/widgets/progress_bar.dart';
import 'breathe_page.dart';
import 'meditate_page.dart';
import 'mindful_shared.dart';
import 'mood_sheet.dart';

/// Mindful minutes a day to aim for.
const mindfulGoalMinutes = 5;

/// Mindfulness: today's mindful minutes, Breathe and Meditate, how you have
/// been feeling, and the week.
class MindfulnessPage extends StatefulWidget {
  const MindfulnessPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const MindfulnessPage());

  @override
  State<MindfulnessPage> createState() => _MindfulnessPageState();
}

class _MindfulnessPageState extends State<MindfulnessPage> {
  late final DateTime _today = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }();
  Stream<List<MindfulSession>>? _sessions;
  Stream<List<MoodEntry>>? _moods;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = HaloScope.mindfulnessOf(context);
    final weekStart = _today.subtract(const Duration(days: 6));
    _sessions ??= repo.watchSessionsSince(weekStart);
    _moods ??= repo.watchMoodsSince(_today.subtract(const Duration(days: 29)));
  }

  @override
  Widget build(BuildContext context) {
    final color = HaloColors.mindfulness.resolveFrom(context);
    final secondary = HaloColors.secondaryLabelOf(context);

    return HaloPage(
      appBar: haloBar(context, title: 'Mindfulness'),
      body: StreamBuilder<List<MindfulSession>>(
        stream: _sessions,
        initialData: const [],
        builder: (context, sessionSnapshot) => StreamBuilder<List<MoodEntry>>(
          stream: _moods,
          initialData: const [],
          builder: (context, moodSnapshot) {
            final sessions = sessionSnapshot.data ?? const [];
            final moods = moodSnapshot.data ?? const [];
            int minutesOn(DateTime day) => sessions
                .where(
                  (s) =>
                      !s.start.isBefore(day) &&
                      s.start.isBefore(day.add(const Duration(days: 1))),
                )
                .fold(0, (t, s) => t + (s.length.inSeconds / 60).round());
            final today = minutesOn(_today);
            final todaysMood = moods
                .where((m) => !m.time.isBefore(_today))
                .firstOrNull;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                HaloMetrics.cardPadding,
                HaloMetrics.topInset(context),
                HaloMetrics.cardPadding,
                HaloMetrics.bottomInset(context),
              ),
              children: [
                HaloCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MINDFUL MINUTES',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$today',
                              style: TextStyle(
                                color: HaloColors.labelOf(context),
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: ' of $mindfulGoalMinutes min today',
                              style: TextStyle(
                                color: secondary,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ProgressBar(
                        value: today / mindfulGoalMinutes,
                        color: color,
                        height: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HaloMetrics.cardGap),
                Row(
                  children: [
                    Expanded(
                      child: _Action(
                        icon: CupertinoIcons.wind,
                        title: 'Breathe',
                        detail: '1–5 min',
                        color: const Color(0xFF5FE0D4),
                        onTap: () =>
                            Navigator.of(context).push(BreathePage.route()),
                      ),
                    ),
                    const SizedBox(width: HaloMetrics.cardGap),
                    Expanded(
                      child: _Action(
                        icon: CupertinoIcons.moon_stars_fill,
                        title: 'Meditate',
                        detail: '5–20 min',
                        color: const Color(0xFFB59CFF),
                        onTap: () =>
                            Navigator.of(context).push(MeditatePage.route()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HaloMetrics.sectionTopGap),
                const GroupCaption('State of Mind'),
                HaloCard(
                  onTap: () => showMoodSheet(context),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: todaysMood == null
                              ? HaloColors.fill.resolveFrom(context)
                              : moodColor(todaysMood.valence),
                        ),
                        child: todaysMood == null
                            ? Icon(
                                CupertinoIcons.plus,
                                color: HaloColors.accent.resolveFrom(context),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todaysMood?.label ?? 'How do you feel?',
                              style: TextStyle(
                                color: HaloColors.labelOf(context),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              todaysMood == null
                                  ? 'Log your mood: it takes a few seconds.'
                                  : [
                                      ...todaysMood.feelings,
                                      ...todaysMood.contexts,
                                    ].take(4).join(' · '),
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
                ),
                const SizedBox(height: HaloMetrics.sectionTopGap),
                const GroupCaption('This Week'),
                HaloCard(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 92,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 6; i >= 0; i--)
                              Expanded(
                                child: () {
                                  final day = _today.subtract(
                                    Duration(days: i),
                                  );
                                  final m = minutesOn(day);
                                  final dayMoods = moods.where(
                                    (e) =>
                                        !e.time.isBefore(day) &&
                                        e.time.isBefore(
                                          day.add(const Duration(days: 1)),
                                        ),
                                  );
                                  final avg = dayMoods.isEmpty
                                      ? null
                                      : (dayMoods.fold<int>(
                                                  0,
                                                  (t, e) => t + e.valence,
                                                ) /
                                                dayMoods.length)
                                            .round();
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: avg == null
                                              ? HaloColors.fill.resolveFrom(
                                                  context,
                                                )
                                              : moodColor(avg),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 16,
                                        height: math.max(
                                          5,
                                          44 *
                                              (m / (mindfulGoalMinutes * 2))
                                                  .clamp(0.0, 1.0),
                                        ),
                                        decoration: ShapeDecoration(
                                          color: m >= mindfulGoalMinutes
                                              ? color
                                              : color.withValues(alpha: 0.4),
                                          shape: const StadiumBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        Format.weekdayLetter(day),
                                        style: TextStyle(
                                          color: i == 0
                                              ? HaloColors.labelOf(context)
                                              : secondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  );
                                }(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const GroupCaption(
                  'Dots are each day’s mood, bars its mindful minutes.',
                  footer: true,
                ),
                if (moods.isNotEmpty) ...[
                  const SizedBox(height: HaloMetrics.sectionTopGap),
                  const GroupCaption('Recent Moods'),
                  GroupedCard(
                    children: [
                      for (final mood in moods.take(10))
                        GroupedRow(
                          leading: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: moodColor(mood.valence),
                            ),
                          ),
                          title: mood.label,
                          value:
                              '${Format.relativeDay(mood.time).split(',').first}, '
                              '${Format.timeOfDay(mood.time)}',
                        ),
                    ],
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

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HaloCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
