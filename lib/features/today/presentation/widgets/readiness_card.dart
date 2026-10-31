import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../app/halo_scope.dart';
import '../../../../app/theme/halo_colors.dart';
import '../../../../app/theme/halo_metrics.dart';
import '../../../../app/theme/halo_motion.dart';
import '../../../../domain/readiness.dart';
import '../../../../domain/sleep.dart';
import '../../../../domain/workout.dart';
import '../../../../shared/format.dart';
import '../../../../shared/widgets/grouped_list.dart';
import '../../../../shared/widgets/halo_card.dart';
import '../../../../shared/widgets/halo_page.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../sleep/presentation/sleep_page.dart';
import '../../../sleep/sleep_controller.dart';

/// Watches what readiness is made of and hands it to [builder].
class _ReadinessData extends StatefulWidget {
  const _ReadinessData({required this.builder});

  final Widget Function(BuildContext context, Readiness? readiness) builder;

  @override
  State<_ReadinessData> createState() => _ReadinessDataState();
}

class _ReadinessDataState extends State<_ReadinessData> {
  Stream<List<SleepNight>>? _nights;
  Stream<List<WorkoutRecord>>? _workouts;
  Stream<SleepSchedule>? _schedule;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = DateTime.now();
    _nights ??= SleepScope.read(context).repository.watchNights(14);
    _workouts ??= HaloScope.workoutsOf(context).watchBetween(
      DateTime(now.year, now.month, now.day - 28),
      DateTime(now.year, now.month, now.day + 1),
    );
    _schedule ??= HaloScope.preferencesOf(context).watchSleepSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SleepSchedule>(
      stream: _schedule,
      initialData: const SleepSchedule(),
      builder: (context, schedule) => StreamBuilder<List<SleepNight>>(
        stream: _nights,
        initialData: const [],
        builder: (context, nights) => StreamBuilder<List<WorkoutRecord>>(
          stream: _workouts,
          initialData: const [],
          builder: (context, workouts) => widget.builder(
            context,
            Readiness.of(
              nights: nights.data ?? const [],
              workouts: workouts.data ?? const [],
              schedule: schedule.data ?? const SleepSchedule(),
              now: DateTime.now(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's readiness: how much the body has in it, from last night, the
/// week's sleep and the recent training load. Until last night is recorded,
/// it says what it needs rather than showing a number it cannot justify.
class ReadinessCard extends StatelessWidget {
  const ReadinessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReadinessData(
      builder: (context, readiness) {
        final accent = HaloColors.accent.resolveFrom(context);
        final secondary = HaloColors.secondaryLabelOf(context);
        return HaloCard(
          onTap: () => Navigator.of(
            context,
          ).push(readiness == null ? SleepPage.route() : ReadinessPage.route()),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (readiness?.value ?? 0) / 100),
                  duration: HaloMotion.of(
                    context,
                    const Duration(milliseconds: 900),
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => CustomPaint(
                    painter: _GaugePainter(
                      track: HaloColors.ringTrack(accent),
                      fill: accent,
                      value: value,
                    ),
                    child: child,
                  ),
                  child: Center(
                    child: Text(
                      readiness == null ? '—' : '${readiness.value}',
                      style: TextStyle(
                        color: readiness == null
                            ? secondary
                            : HaloColors.labelOf(context),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.bolt_fill, size: 15, color: accent),
                        const SizedBox(width: 5),
                        Text(
                          'Readiness',
                          style: TextStyle(
                            color: accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      readiness?.label ?? 'Not Enough Data',
                      style: TextStyle(
                        color: HaloColors.labelOf(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      readiness == null
                          ? 'Record last night’s sleep to see how ready you '
                                'are this morning.'
                          : 'Sleep ${Format.durationWords(readiness.weekAverage)}'
                                ' a night · Load ${readiness.loadLabel.toLowerCase()}',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// What today's readiness is made of.
class ReadinessPage extends StatelessWidget {
  const ReadinessPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const ReadinessPage());

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'Readiness'),
      body: _ReadinessData(
        builder: (context, readiness) {
          final accent = HaloColors.accent.resolveFrom(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              HaloMetrics.cardPadding,
              HaloMetrics.topInset(context),
              HaloMetrics.cardPadding,
              HaloMetrics.bottomInset(context),
            ),
            children: [
              if (readiness == null)
                const GroupCaption(
                  'Record last night’s sleep to see your readiness.',
                  footer: true,
                )
              else ...[
                HaloCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${readiness.value}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HaloColors.labelOf(context),
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.5,
                        ),
                      ),
                      Text(
                        readiness.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HaloMetrics.cardGap),
                HaloCard(
                  child: Column(
                    children: [
                      _Part(
                        title: 'Last Night',
                        detail:
                            'Sleep score ${(readiness.lastNight * 100).round()}',
                        value: readiness.lastNight,
                        color: HaloColors.sleep.resolveFrom(context),
                      ),
                      _Part(
                        title: 'This Week’s Sleep',
                        detail:
                            '${Format.durationWords(readiness.weekAverage)} a night',
                        value: readiness.sleepWeek,
                        color: HaloColors.sleep.resolveFrom(context),
                      ),
                      _Part(
                        title: 'Training Load',
                        detail: readiness.loadRatio == null
                            ? readiness.loadLabel
                            : '${readiness.loadLabel} · '
                                  '${readiness.loadRatio!.toStringAsFixed(2)}×',
                        value: readiness.load,
                        color: HaloColors.move.resolveFrom(context),
                        last: true,
                      ),
                    ],
                  ),
                ),
                const GroupCaption(
                  'Half from last night’s sleep, a little from the week’s, '
                  'and the rest from how this week’s training compares with '
                  'the last four. Without a watch there is no heart rate in '
                  'it: a guide, not a measurement.',
                  footer: true,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({
    required this.title,
    required this.detail,
    required this.value,
    required this.color,
    this.last = false,
  });

  final String title;
  final String detail;
  final double value;
  final Color color;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                detail,
                style: TextStyle(
                  color: HaloColors.secondaryLabelOf(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(value: value, color: color),
        ],
      ),
    );
  }
}

/// A three-quarter gauge, open at the bottom, filled to [value].
class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.track, required this.fill, required this.value});

  final Color track;
  final Color fill;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      paint..color = track,
    );
    if (value > 0) {
      canvas.drawArc(
        rect,
        math.pi * 0.75,
        math.pi * 1.5 * value.clamp(0.0, 1.0),
        false,
        paint..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.track != track || old.fill != fill || old.value != value;
}
