import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/preferences/halo_preferences.dart';
import '../domain/today_card.dart';

/// Opens Edit Summary: choose which cards Today shows, and in what order.
///
/// A sheet, the way Fitness edits its Summary: the list is the page's cards,
/// with a delete badge and a grabber on each shown card and an insert badge on
/// each hidden one. Every change is written straight away, so there is no
/// Cancel to lose work to; Done only closes.
Future<void> showEditTodaySheet(BuildContext context) async {
  final preferences = HaloScope.preferencesOf(context);
  final current = await preferences.watchTodayCards().first;
  if (!context.mounted) return;

  await GlassModalSheet.show<void>(
    context: context,
    initialState: GlassSheetState.full,
    detents: const {GlassSheetDetent.large},
    settings: HaloGlass.of(context),
    quality: HaloGlass.quality,
    builder: (_) => _EditTodaySheet(
      preferences: preferences,
      initial: current,
    ),
  );
}

class _EditTodaySheet extends StatefulWidget {
  const _EditTodaySheet({required this.preferences, required this.initial});

  final HaloPreferences preferences;
  final List<TodayCard> initial;

  @override
  State<_EditTodaySheet> createState() => _EditTodaySheetState();
}

class _EditTodaySheetState extends State<_EditTodaySheet> {
  late List<TodayCard> _shown = List.of(widget.initial);

  List<TodayCard> get _hidden => [
        for (final card in TodayCard.values)
          if (!_shown.contains(card)) card,
      ];

  void _update(List<TodayCard> next) {
    setState(() => _shown = next);
    widget.preferences.setTodayCards(next);
  }

  @override
  Widget build(BuildContext context) {
    // `GlassListTile` replaces the ambient text style rather than merging into
    // it, so the row title is given the app's own style explicitly. Otherwise
    // it would drop the app font the moment one is set.
    final rowTitle = DefaultTextStyle.of(context).style.copyWith(
          color: HaloColors.labelOf(context),
          fontSize: 17,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        HaloMetrics.cardPadding,
        8,
        HaloMetrics.cardPadding,
        32,
      ),
      children: [
        _Header(onDone: () => Navigator.of(context).pop()),
        const SizedBox(height: 12),
        const _SectionLabel('Shown on Today'),
        GlassReorderableList.grouped(
          surfaceStyle: GlassSurfaceStyle.solid,
          itemCount: _shown.length,
          // `onReorderItem` hands over the index the item settled at, already
          // adjusted for its own removal.
          onReorderItem: (from, to) {
            final next = List.of(_shown);
            next.insert(to, next.removeAt(from));
            _update(next);
          },
          itemBuilder: (context, index) {
            final card = _shown[index];
            return GlassListTile(
              key: ValueKey(card),
              isEditing: true,
              canDelete: true,
              onDelete: () => _update(List.of(_shown)..remove(card)),
              canReorder: true,
              reorderIndex: index,
              leading: _CardGlyph(card: card),
              titleStyle: rowTitle,
              title: Text(card.title),
            );
          },
        ),
        if (_hidden.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionLabel('More Cards'),
          GlassGroupedSection(
            // The list above already sits inside the page padding; the
            // section's own default margin would inset it a second time.
            margin: EdgeInsets.zero,
            surfaceStyle: GlassSurfaceStyle.solid,
            children: [
              for (final card in _hidden)
                GlassListTile(
                  key: ValueKey(card),
                  isEditing: true,
                  canInsert: true,
                  onInsert: () => _update([..._shown, card]),
                  leading: _CardGlyph(card: card),
                  titleStyle: rowTitle,
                  title: Text(card.title),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HaloMetrics.barButtonSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Edit Summary',
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: HaloMetrics.barTitleSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(44, 44),
              onPressed: onDone,
              child: Text(
                'Done',
                style: TextStyle(
                  color: HaloColors.accent.resolveFrom(context),
                  fontSize: HaloMetrics.barButtonTextSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: HaloColors.secondaryLabelOf(context),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A card's glyph on a rounded tile of its colour, as Settings draws its row
/// icons.
class _CardGlyph extends StatelessWidget {
  const _CardGlyph({required this.card});

  final TodayCard card;

  @override
  Widget build(BuildContext context) {
    final color = card.color.resolveFrom(context);
    return Container(
      width: 28,
      height: 28,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(7),
        ),
        color: color,
      ),
      alignment: Alignment.center,
      child: Icon(
        card.icon,
        size: 17,
        color: card == TodayCard.readiness
            ? HaloColors.onAccent.resolveFrom(context)
            : const Color(0xFFFFFFFF),
      ),
    );
  }
}
