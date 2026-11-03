import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../app/theme/halo_motion.dart';
import '../../../domain/nutrition.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/day_bars.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_alert.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';

/// Water, quickly: how much today against the target, a tap per glass or
/// bottle, what was logged, and the week.
class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const WaterPage());

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  Stream<List<(int, DateTime, int)>>? _week;

  /// How far back the chart goes.
  static const _days = 90;

  /// The day whose entries are listed: today until another is tapped.
  DateTime? _selected;
  late final DateTime _today = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }();

  /// A sip, a glass, a mug, a bottle.
  static const _amounts = [
    (150, 'Sip', Icons.water_drop_outlined),
    (250, 'Glass', Icons.local_drink_rounded),
    (330, 'Mug', Icons.coffee_rounded),
    (500, 'Bottle', Icons.water_drop_rounded),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _week ??= HaloScope.nutritionOf(context).watchWaterBetween(
      _today.subtract(const Duration(days: _days - 1)),
      _today.add(const Duration(days: 1)),
    );
  }

  Future<void> _add(int ml) async {
    HapticFeedback.mediumImpact();
    await HaloScope.nutritionOf(context).addWater(DateTime.now(), ml);
  }

  Future<void> _remove(int id, int ml) async {
    final nutrition = HaloScope.nutritionOf(context);
    final remove = await confirmDestructive(
      context,
      title: 'Remove $ml ml?',
      action: 'Remove',
    );
    if (remove) await nutrition.deleteWater(id);
  }

  @override
  Widget build(BuildContext context) {
    final profile = HaloScope.activityOf(context).profile;
    final target = NutritionTargets.of(
      profile,
      const WeightGoal(),
      today: _today,
    ).waterMl;
    final color = HaloColors.hydration.resolveFrom(context);

    return HaloPage(
      appBar: haloBar(context, title: 'Water'),
      body: StreamBuilder<List<(int, DateTime, int)>>(
        stream: _week,
        initialData: const [],
        builder: (context, snapshot) {
          final week = snapshot.data ?? const [];
          final today = [
            for (final w in week)
              if (!w.$2.isBefore(_today)) w,
          ];
          final ml = today.fold<int>(0, (t, w) => t + w.$3);
          final perDay = List.filled(_days, 0);
          for (final w in week) {
            final day = DateTime(w.$2.year, w.$2.month, w.$2.day);
            // Counted in calendar days, so a clock change does not shift one.
            final i =
                _days -
                1 -
                DateTime.utc(
                  _today.year,
                  _today.month,
                  _today.day,
                ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
            if (i >= 0 && i < _days) perDay[i] += w.$3;
          }
          final selected = _selected ?? _today;
          final listed = [
            for (final w in week)
              if (isSameDay(w.$2, selected)) w,
          ];

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
                  children: [
                    SizedBox.square(
                      dimension: 180,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: (ml / target).clamp(0.0, 1.0)),
                        duration: HaloMotion.of(
                          context,
                          const Duration(milliseconds: 700),
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => CustomPaint(
                          painter: _Drop(value: value, color: color),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Format.litres(ml),
                                  style: TextStyle(
                                    color: HaloColors.labelOf(context),
                                    fontSize: 44,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  'of ${Format.litres(target)} L',
                                  style: TextStyle(
                                    color: HaloColors.secondaryLabelOf(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        for (final (amount, label, icon) in _amounts)
                          Expanded(
                            child: _AddButton(
                              ml: amount,
                              label: label,
                              icon: icon,
                              color: color,
                              onTap: () => _add(amount),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HaloMetrics.sectionTopGap),
              const GroupCaption('Days'),
              HaloCard(
                child: DayBars(
                  values: [for (final v in perDay) v.toDouble()],
                  lastDay: _today,
                  color: color,
                  goal: target.toDouble(),
                  describe: (v) => '${Format.litres(v.round())} L',
                  onSelect: (day) => setState(() => _selected = day),
                ),
              ),
              if (listed.isNotEmpty) ...[
                const SizedBox(height: HaloMetrics.sectionTopGap),
                GroupCaption(Format.relativeDay(selected)),
                GroupedCard(
                  children: [
                    for (final (id, time, amount) in listed.reversed)
                      GroupedRow(
                        title: Format.timeOfDay(time),
                        value: '$amount ml',
                        onTap: () => _remove(id, amount),
                      ),
                  ],
                ),
                const GroupCaption('Tap an entry to remove it.', footer: true),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.ml,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final int ml;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add $ml millilitres',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              '+$ml',
              style: TextStyle(
                color: HaloColors.labelOf(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: HaloColors.secondaryLabelOf(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A ring that fills with the day's water.
class _Drop extends CustomPainter {
  _Drop({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = HaloColors.ringTrack(color),
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Drop old) => old.value != value || old.color != color;
}
