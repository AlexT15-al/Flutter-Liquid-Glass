import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

import '../../shared/widgets/rings_glyph.dart';

/// The four destinations of the tab bar, in order.
///
/// The enum is the single source of truth for a tab's identity: its label, its
/// page title and its glyph. Nothing else holds a tab index.
enum HaloTab {
  today(title: 'Today'),
  workout(title: 'Workout'),
  nutrition(title: 'Nutrition'),
  plans(title: 'Plans');

  const HaloTab({required this.title});

  /// Both the tab-bar label and the page title.
  final String title;

  /// The tab's glyph, always the filled variant.
  ///
  /// iOS 26 tab bars do not swap outline for fill on selection: the indicator
  /// and the accent tint carry the selection, and an outline glyph beside
  /// filled ones reads as a different icon family.
  ///
  /// A widget rather than `IconData` because Today's rings are drawn, and the
  /// running figure, the knife and fork and the calendar come from the
  /// Material set, which has the filled glyphs Cupertino icons lack. Both take their colour from the tab bar's
  /// `IconTheme`, so the bar tints them like any other glyph.
  Widget get glyph => switch (this) {
    HaloTab.today => const RingsGlyph(),
    HaloTab.workout => const Icon(Icons.directions_run_rounded),
    HaloTab.nutrition => const Icon(Icons.restaurant_rounded),
    HaloTab.plans => const Icon(Icons.calendar_month_rounded),
  };
}
