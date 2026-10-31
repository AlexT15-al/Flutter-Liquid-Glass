import 'package:flutter/cupertino.dart';

import '../../../app/theme/halo_colors.dart';

/// A card the Today page can show, in the order it can be offered in.
///
/// The Activity rings are not here: they are the page's anchor, always first,
/// the way Fitness keeps the Activity card at the top of Summary.
enum TodayCard {
  readiness(
    title: 'Readiness',
    icon: CupertinoIcons.bolt_fill,
    color: HaloColors.accent,
    wide: true,
  ),
  steps(
    title: 'Steps',
    icon: CupertinoIcons.flame_fill,
    color: HaloColors.activity,
  ),
  distance(
    title: 'Distance',
    icon: CupertinoIcons.location_fill,
    color: HaloColors.activity,
  ),
  sleep(
    title: 'Sleep',
    icon: CupertinoIcons.bed_double_fill,
    color: HaloColors.sleep,
  ),
  water(
    title: 'Water',
    icon: CupertinoIcons.drop_fill,
    color: HaloColors.hydration,
  ),
  heartRate(
    title: 'Heart Rate',
    icon: CupertinoIcons.heart_fill,
    color: HaloColors.heart,
  ),
  nutrition(
    title: 'Nutrition',
    icon: CupertinoIcons.chart_pie_fill,
    color: HaloColors.nutrition,
  ),
  weight(
    title: 'Weight',
    icon: CupertinoIcons.person_fill,
    color: HaloColors.body,
  ),
  mindfulness(
    title: 'Mindfulness',
    icon: CupertinoIcons.sparkles,
    color: HaloColors.mindfulness,
  );

  const TodayCard({
    required this.title,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  final String title;
  final IconData icon;

  /// The category colour, used for the title and the glyph, as in Health.
  final CupertinoDynamicColor color;

  /// Spans the full width rather than half a row.
  final bool wide;

  /// What a new install shows, in order.
  static const defaults = [
    TodayCard.readiness,
    TodayCard.steps,
    TodayCard.distance,
    TodayCard.sleep,
    TodayCard.water,
    TodayCard.heartRate,
    TodayCard.nutrition,
  ];
}
