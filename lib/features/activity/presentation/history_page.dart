import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/activity/activity_history.dart';
import '../../../domain/activity_goals.dart';
import '../../../domain/activity_summary.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/halo_alert.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';

/// Every day's rings, a month to a card, newest month first.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const HistoryPage());

  static const _months = 12;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return HaloPage(
      appBar: haloBar(context, title: 'History'),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          HaloMetrics.cardPadding,
          HaloMetrics.topInset(context),
          HaloMetrics.cardPadding,
          HaloMetrics.bottomInset(context),
        ),
        itemCount: _months,
        separatorBuilder: (_, _) => const SizedBox(height: HaloMetrics.cardGap),
        itemBuilder: (context, i) =>
            _MonthCard(month: DateTime(now.year, now.month - i)),
      ),
    );
  }
}

class _MonthCard extends StatefulWidget {
  const _MonthCard({required this.month});

  final DateTime month;

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  Future<List<ActivitySummary>>? _days;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_days != null) return;
    final now = DateTime.now();
    final first = widget.month;
    final last = DateTime(first.year, first.month + 1, 0);
    final to = last.isAfter(now) ? now : last;
    _days = ActivityHistory(
      HaloScope.databaseOf(context),
      HaloScope.workoutsOf(context),
    ).days(first, to, HaloScope.activityOf(context).profile);
  }

  void _show(ActivitySummary day, ActivityGoals goals) {
    showHaloAlert<void>(
      context,
      title: Format.longDate(day.day),
      message:
          'Move ${Format.integer(day.activeKcal)} of ${goals.moveKcal} kcal\n'
          'Exercise ${day.exerciseMinutes.round()} of '
          '${goals.exerciseMinutes} min\n'
          'Active Hours ${day.activeHours} of ${goals.activeHours}\n'
          '${Format.integer(day.steps)} steps',
      actions: const [HaloAlertAction('OK', style: HaloAlertStyle.primary)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = HaloScope.activityOf(context).goals;
    final first = widget.month;
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final offset = first.weekday - 1;
    final secondary = HaloColors.secondaryLabelOf(context);

    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Format.monthName(first)} ${first.year}',
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final letter in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Text(
                    letter,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          FutureBuilder<List<ActivitySummary>>(
            future: _days,
            builder: (context, snapshot) {
              final days = snapshot.data ?? const <ActivitySummary>[];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 52,
                ),
                itemCount: offset + daysInMonth,
                itemBuilder: (context, i) {
                  if (i < offset) return const SizedBox.shrink();
                  final dayNumber = i - offset + 1;
                  final summary = dayNumber <= days.length
                      ? days[dayNumber - 1]
                      : null;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: summary == null ? null : () => _show(summary, goals),
                    child: Column(
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox.square(
                          dimension: 34,
                          child: CustomPaint(
                            painter: MiniRings(
                              values: summary == null
                                  ? const [0, 0, 0]
                                  : [
                                      summary.activeKcal / goals.moveKcal,
                                      summary.exerciseMinutes /
                                          goals.exerciseMinutes,
                                      summary.activeHours / goals.activeHours,
                                    ],
                              colors: [
                                HaloColors.move.resolveFrom(context),
                                HaloColors.exercise.resolveFrom(context),
                                HaloColors.activeHours.resolveFrom(context),
                              ],
                              faded: summary == null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Three small concentric rings, static: a calendar draws dozens of them.
class MiniRings extends CustomPainter {
  MiniRings({required this.values, required this.colors, this.faded = false});

  final List<double> values;
  final List<Color> colors;
  final bool faded;

  @override
  void paint(Canvas canvas, Size size) {
    final d = math.min(size.width, size.height);
    final stroke = d * 0.12;
    final gap = d * 0.03;
    for (var i = 0; i < 3; i++) {
      final inset = stroke / 2 + i * (stroke + gap);
      final rect = Rect.fromLTWH(inset, inset, d - inset * 2, d - inset * 2);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        paint
          ..color = HaloColors.ringTrack(
            colors[i],
          ).withValues(alpha: faded ? 0.08 : 0.22),
      );
      final v = values[i].clamp(0.0, 1.0);
      if (v > 0) {
        canvas.drawArc(
          rect,
          -math.pi / 2,
          math.pi * 2 * v,
          false,
          paint..color = colors[i],
        );
      }
    }
  }

  @override
  bool shouldRepaint(MiniRings old) =>
      old.values != values || old.colors != colors || old.faded != faded;
}
